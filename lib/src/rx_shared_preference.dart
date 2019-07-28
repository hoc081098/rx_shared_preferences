import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:rx_shared_preference/src/interface/i_rx_shared_preferences.dart';
import 'package:rx_shared_preference/src/logger/logger.dart';
import 'package:rx_shared_preference/src/model/key_and_value.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

///
///
///
class RxSharedPreferences implements IRxSharedPreferences {
  ///
  /// Properties
  ///

  // ignore: close_sinks
  final _keyValuesSubject = PublishSubject<Iterable<KeyAndValue<dynamic>>>();
  final Future<SharedPreferences> _sharedPrefsFuture;
  final Logger _logger;

  ///
  /// Constructor
  ///

  RxSharedPreferences(
    FutureOr<SharedPreferences> sharedPreference, [
    this._logger,
  ])  : assert(sharedPreference != null),
        _sharedPrefsFuture = Future.value(sharedPreference) {
    _keyValuesSubject
        .listen((pairs) => _logger?.keysChanged(UnmodifiableListView(pairs)));
  }

  ///
  /// Internal
  ///

  ///
  /// Workaround to capture generics
  ///
  static Type _typeOf<T>() => T;

  ///
  /// Get [Observable] from the persistent storage
  ///
  Observable<T> _getObservable<T>(String key, Future<T> get(String key)) {
    return _keyValuesSubject
        .map((pairs) {
          return pairs.firstWhere(
            (pair) => pair.key == key,
            orElse: () => null,
          );
        })
        .where((pair) => pair != null)
        .startWith(null) // Dummy value to trigger initial load.
        .asyncMap((pair) async {
          if (pair == null) {
            return get(key);
          }
          if (T == _typeOf<List<String>>()) {
            return (pair.value as List)?.cast<String>() as T;
          }
          return pair.value as T;
        })
        .doOnData(
            (value) => _logger?.doOnDataObservable(KeyAndValue(key, value)))
        .doOnError((e, StackTrace s) => _logger?.doOnErrorObservable(e, s));
  }

  ///
  /// Get value from the persistent storage by [key]
  ///
  Future<T> _get<T>([String key]) async {
    read<T>(SharedPreferences sharedPreferences, String key) {
      if (T == dynamic) {
        return sharedPreferences.get(key) as T;
      }
      if (T == double) {
        return sharedPreferences.getDouble(key) as T;
      }
      if (T == int) {
        return sharedPreferences.getInt(key) as T;
      }
      if (T == bool) {
        return sharedPreferences.getBool(key) as T;
      }
      if (T == String) {
        return sharedPreferences.getString(key) as T;
      }
      if (T == _typeOf<List<String>>()) {
        return sharedPreferences.getStringList(key)?.cast<String>() as T;
      }
      // Get all keys
      if (T == _typeOf<Set<String>>() && key == null) {
        return sharedPreferences.getKeys() as T;
      }
      return null;
    }

    final sharedPreferences = await _sharedPrefsFuture;
    final value = read<T>(sharedPreferences, key);
    _logger?.readValue(T, key, value);

    return value;
  }

  ///
  /// Set [value] associated with [key]
  ///
  Future<bool> _setValue<T>(String key, T value) async {
    write<T>(SharedPreferences sharedPreferences, String key, T value) {
      if (T == dynamic) {
        return value != null
            ? Future.value(false)
            : sharedPreferences.remove(key);
      }
      if (T == double) {
        return sharedPreferences.setDouble(key, value as double);
      }
      if (T == int) {
        return sharedPreferences.setInt(key, value as int);
      }
      if (T == bool) {
        return sharedPreferences.setBool(key, value as bool);
      }
      if (T == String) {
        return sharedPreferences.setString(key, value as String);
      }
      if (T == _typeOf<List<String>>()) {
        return sharedPreferences.setStringList(
          key,
          (value as List)?.cast<String>(),
        );
      }
      return Future.value(false);
    }

    final sharedPreferences = await _sharedPrefsFuture;
    final result = (await write<T>(sharedPreferences, key, value)) ?? false;
    _logger?.writeValue(T, key, value, result);

    // Trigger key changes
    if (result) {
      _keyValuesSubject.add([KeyAndValue<T>(key, value)]);
    }

    return result;
  }

  ///
  /// Delegate to [SharedPreferences]
  ///

  ///
  /// Returns a future complete with value true if the persistent storage
  /// contains the given [key].
  ///
  Future<bool> containsKey(String key) => _sharedPrefsFuture
      .then((sharedPreferences) => sharedPreferences.containsKey(key));

  ///
  /// Reads a value of any type from persistent storage.
  ///
  Future<dynamic> get(String key) => _get<dynamic>(key);

  ///
  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a bool.
  ///
  Future<bool> getBool(String key) => _get<bool>(key);

  ///
  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a double.
  ///
  Future<double> getDouble(String key) => _get<double>(key);

  ///
  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a int.
  ///
  Future<int> getInt(String key) => _get<int>(key);

  ///
  /// Returns all keys in the persistent storage.
  ///
  Future<Set<String>> getKeys() => _get<Set<String>>();

  ///
  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a String.
  ///
  Future<String> getString(String key) => _get<String>(key);

  ///
  /// Reads a value from persistent storage, return a future that completes
  /// with an error if it's not a string set.
  ///
  Future<List<String>> getStringList(String key) => _get<List<String>>(key);

  ///
  /// Completes with true once the user preferences for the app has been cleared.
  ///
  Future<bool> clear() async {
    final SharedPreferences sharedPreferences = await _sharedPrefsFuture;
    final Set<String> keys = sharedPreferences.getKeys();
    final bool result = await sharedPreferences.clear();
    if (result ?? false) {
      _keyValuesSubject.add(keys.map((key) => KeyAndValue<dynamic>(key, null)));
    }
    return result;
  }

  /// Fetches the latest values from the host platform.
  ///
  /// Use this method to observe modifications that were made in native code
  /// (without using the plugin) while the app is running.
  Future<void> reload() async {
    final SharedPreferences sharedPreferences = await _sharedPrefsFuture;
    await sharedPreferences.reload();
    _keyValuesSubject.add(sharedPreferences
        .getKeys()
        .map((key) => KeyAndValue(key, sharedPreferences.get(key))));
  }

  /// Always returns true.
  /// On iOS, synchronize is marked deprecated. On Android, we commit every set.
  @deprecated
  Future<bool> commit() =>
      _sharedPrefsFuture.then((sharedPrefs) => sharedPrefs.commit());

  ///
  /// Removes an entry from persistent storage.
  ///
  Future<bool> remove(String key) => _setValue<dynamic>(key, null);

  ///
  /// Saves a boolean [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  ///
  Future<bool> setBool(String key, bool value) => _setValue<bool>(key, value);

  ///
  /// Saves a double [value] to persistent storage in the background.
  ///
  /// Android doesn't support storing doubles, so it will be stored as a float.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  ///
  Future<bool> setDouble(String key, double value) =>
      _setValue<double>(key, value);

  ///
  /// Saves an integer [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  ///
  Future<bool> setInt(String key, int value) => _setValue<int>(key, value);

  ///
  /// Saves a string [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  ///
  Future<bool> setString(String key, String value) =>
      _setValue<String>(key, value);

  ///
  /// Saves a list of strings [value] to persistent storage in the background.
  ///
  /// If [value] is null, this is equivalent to calling [remove()] on the [key].
  ///
  Future<bool> setStringList(String key, List<String> value) =>
      _setValue<List<String>>(key, value);

  /// Initializes the shared preferences with mock values for testing.
  ///
  /// If the singleton instance has been initialized already, it is automatically reloaded.
  @visibleForTesting
  static void setMockInitialValues(Map<String, dynamic> values) {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(values);
  }

  ///
  /// Get observables (implements [IRxSharedPreferences])
  ///

  @override
  Observable<dynamic> getObservable(String key) =>
      _getObservable<dynamic>(key, get);

  @override
  Observable<bool> getBoolObservable(String key) =>
      _getObservable<bool>(key, getBool);

  @override
  Observable<double> getDoubleObservable(String key) =>
      _getObservable<double>(key, getDouble);

  @override
  Observable<int> getIntObservable(String key) =>
      _getObservable<int>(key, getInt);

  @override
  Observable<String> getStringObservable(String key) =>
      _getObservable<String>(key, getString);

  @override
  Observable<List<String>> getStringListObservable(String key) =>
      _getObservable<List<String>>(key, getStringList);
}
