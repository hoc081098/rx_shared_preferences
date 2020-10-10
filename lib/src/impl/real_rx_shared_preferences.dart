import 'dart:async';
import 'dart:collection';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../rx_shared_preferences.dart';
import '../config/global_config.dart';
import '../interface/rx_shared_preferences.dart';
import '../logger/logger.dart';
import '../model/key_and_value.dart';
import '../stream_extensions/map_not_null_stream_transformer.dart';
import '../stream_extensions/single_subscription.dart';

///
/// Default [RxSharedPreferences] implementation
///
class RealRxSharedPreferences implements RxSharedPreferences {
  ///
  /// Trigger subject
  ///
  final _keyValuesSubject = PublishSubject<Map<String, dynamic>>();
  StreamSubscription<dynamic> _subscription;

  ///
  /// Future of [SharedPreferences]
  ///
  final Future<SharedPreferences> _sharedPrefsFuture;

  ///
  /// Logger
  ///
  final Logger _logger;

  /// On dispose
  void Function() _onDispose;

  ///
  /// Construct a [RealRxSharedPreferences] with [sharedPreference] and optional logger
  ///
  RealRxSharedPreferences(
    FutureOr<SharedPreferences> sharedPreference, [
    this._logger,
    this._onDispose,
  ])  : assert(sharedPreference != null),
        _sharedPrefsFuture = Future.value(sharedPreference) {
    _subscription = _keyValuesSubject.listen((map) {
      final pairs = map.entries.map((entry) => KeyAndValue.fromMapEntry(entry));
      _logger?.keysChanged(UnmodifiableListView(pairs));
    });
  }

  static RealRxSharedPreferences _defaultInstance;

  ///
  /// Return default singleton instance
  ///
  factory RealRxSharedPreferences.getInstance() =>
      _defaultInstance ??= RealRxSharedPreferences(
        SharedPreferences.getInstance(),
        RxSharedPreferencesConfigs.logger,
        () => _defaultInstance = null,
      );

  //
  // Internal
  //

  ///
  /// Workaround to capture generics
  ///
  static Type _typeOf<T>() => T;

  ///
  /// Get [Stream] from the persistent storage
  ///
  Stream<T> _getStream<T>(String key, Future<T> Function(String key) get) {
    return _keyValuesSubject
        .toSingleSubscriptionStream()
        .mapNotNull((map) {
          if (map.containsKey(key)) {
            return MapEntry(key, map[key]);
          } else {
            return null;
          }
        })
        .startWith(null) // Dummy value to trigger initial load.
        .asyncMap((entry) async {
          if (entry == null) {
            // Initial reading
            return get(key);
          } else {
            return entry.value as T;
          }
        })
        .doOnData((value) => _logger?.doOnDataStream(KeyAndValue(key, value)))
        .doOnError((e, StackTrace s) => _logger?.doOnErrorStream(e, s));
  }

  ///
  /// Read value from SharedPreferences by [key]
  ///
  static T _readFromSharedPreferences<T>(
    SharedPreferences sharedPrefs,
    String key,
  ) {
    if (T == dynamic) {
      return sharedPrefs.get(key) as T;
    }
    if (T == double) {
      return sharedPrefs.getDouble(key) as T;
    }
    if (T == int) {
      return sharedPrefs.getInt(key) as T;
    }
    if (T == bool) {
      return sharedPrefs.getBool(key) as T;
    }
    if (T == String) {
      return sharedPrefs.getString(key) as T;
    }
    if (T == _typeOf<List<String>>()) {
      return sharedPrefs.getStringList(key) as T;
    }
    // Get all keys
    if (T == _typeOf<Set<String>>() && key == null) {
      return sharedPrefs.getKeys() as T;
    }
    return null;
  }

  ///
  /// Get value from the persistent storage by [key]
  ///
  Future<T> _get<T>([String key]) async {
    final prefs = await _sharedPrefsFuture;
    final value = _readFromSharedPreferences<T>(prefs, key);
    _logger?.readValue(T, key, value);

    return value;
  }

  ///
  /// Write [value] to SharedPreferences associated with [key]
  ///
  static Future<bool> _writeToSharedPreferences<T>(
    SharedPreferences sharedPrefs,
    String key,
    T value,
  ) {
    if (T == dynamic && value == null) {
      return sharedPrefs.remove(key);
    }
    if (T == double) {
      return sharedPrefs.setDouble(key, value as double);
    }
    if (T == int) {
      return sharedPrefs.setInt(key, value as int);
    }
    if (T == bool) {
      return sharedPrefs.setBool(key, value as bool);
    }
    if (T == String) {
      return sharedPrefs.setString(key, value as String);
    }
    if (T == _typeOf<List<String>>()) {
      return sharedPrefs.setStringList(
        key,
        value as List<String>,
      );
    }
    return null;
  }

  ///
  /// Set [value] associated with [key]
  ///
  Future<bool> _setValue<T>(String key, T value) async {
    final prefs = await _sharedPrefsFuture;
    final result = await _writeToSharedPreferences<T>(prefs, key, value);
    _logger?.writeValue(T, key, value, result);

    // Trigger key changes
    if (result ?? false) {
      _sendKeyValueChanged({key: value});
    }

    return result;
  }

  ///
  /// Add pairs to subject to trigger.
  /// Do nothing if subject already closed.
  ///
  void _sendKeyValueChanged(Map<String, dynamic> map) {
    try {
      _keyValuesSubject.add(map);
    } catch (e) {
      print(e);
      // Do nothing
    }
  }

  //
  // Get and set methods (implements [ILikeSharedPreferences])
  //

  @override
  Future<bool> containsKey(String key) =>
      _sharedPrefsFuture.then((prefs) => prefs.containsKey(key));

  @override
  Future<dynamic> get(String key) => _get<dynamic>(key);

  @override
  Future<bool> getBool(String key) => _get<bool>(key);

  @override
  Future<double> getDouble(String key) => _get<double>(key);

  @override
  Future<int> getInt(String key) => _get<int>(key);

  @override
  Future<Set<String>> getKeys() => _get<Set<String>>();

  @override
  Future<String> getString(String key) => _get<String>(key);

  @override
  Future<List<String>> getStringList(String key) => _get<List<String>>(key);

  @override
  Future<bool> clear() async {
    final prefs = await _sharedPrefsFuture;
    final keys = prefs.getKeys();
    final result = await prefs.clear();

    // Log: all values are set to null
    for (final key in keys) {
      _logger?.writeValue(dynamic, key, null, result);
    }

    // Trigger key changes: all values are set to null
    if (result ?? false) {
      final map = {for (final k in keys) k: null};
      _sendKeyValueChanged(map);
    }

    return result;
  }

  @override
  Future<void> reload() async {
    final prefs = await _sharedPrefsFuture;
    await prefs.reload();

    // Log: read value from prefs
    for (final key in prefs.getKeys()) {
      _logger?.readValue(dynamic, key, prefs.get(key));
    }

    // Trigger key changes: read value from prefs
    final map = {for (final k in prefs.getKeys()) k: prefs.get(k)};
    _sendKeyValueChanged(map);
  }

  @override
  Future<bool> remove(String key) => _setValue<dynamic>(key, null);

  @override
  Future<bool> setBool(String key, bool value) => _setValue<bool>(key, value);

  @override
  Future<bool> setDouble(String key, double value) =>
      _setValue<double>(key, value);

  @override
  Future<bool> setInt(String key, int value) => _setValue<int>(key, value);

  @override
  Future<bool> setString(String key, String value) =>
      _setValue<String>(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _setValue<List<String>>(key, value);

  //
  // Get streams (implements [IRxSharedPreferences])
  //

  @override
  Stream<dynamic> getStream(String key) => _getStream<dynamic>(key, get);

  @override
  Stream<bool> getBoolStream(String key) => _getStream<bool>(key, getBool);

  @override
  Stream<double> getDoubleStream(String key) =>
      _getStream<double>(key, getDouble);

  @override
  Stream<int> getIntStream(String key) => _getStream<int>(key, getInt);

  @override
  Stream<String> getStringStream(String key) =>
      _getStream<String>(key, getString);

  @override
  Stream<List<String>> getStringListStream(String key) =>
      _getStream<List<String>>(key, getStringList);

  @override
  Stream<Set<String>> getKeysStream() => _keyValuesSubject
      .toSingleSubscriptionStream()
      .startWith(null)
      .asyncMap((_) => getKeys());

  @override
  Future<void> dispose() async {
    final futures = [_keyValuesSubject.close(), _subscription?.cancel()]
        .where((future) => future != null);
    await Future.wait(futures);

    _onDispose?.call();
  }
}
