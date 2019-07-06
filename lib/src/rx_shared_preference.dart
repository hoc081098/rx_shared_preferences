import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

///
/// Get [Observable]s by key from persistent storage.
///
abstract class IRxSharedPreferences {
  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with key was changed.
  ///
  Observable<dynamic> getObservable(String key);

  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This observable will emit an error if it's not a bool.
  ///
  Observable<bool> getBoolObservable(String key);

  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This observable will emit an error if it's not a double.
  ///
  Observable<double> getDoubleObservable(String key);

  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This observable will emit an error if it's not a int.
  ///
  Observable<int> getIntObservable(String key);

  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This observable will emit an error if it's not a String.
  ///
  Observable<String> getStringObservable(String key);

  ///
  /// Return [Observable] that will emit value read from persistent storage.
  /// It will automatic emit value when value associated with [key] was changed.
  /// This observable will emit an error if it's not a string set.
  ///
  Observable<List<String>> getStringListObservable(String key);
}

typedef void Logger(String message);

///
///
///
class RxSharedPreferences implements IRxSharedPreferences {
  // ignore: close_sinks
  final PublishSubject<Iterable<_KeyAndValueChanged<dynamic>>>
      _keyValuesChangedSubject = PublishSubject();
  final Future<SharedPreferences> _sharedPreferencesFuture;
  final Logger _logger;

  RxSharedPreferences(
    FutureOr<SharedPreferences> sharedPreference, [
    Logger logger,
  ])  : assert(sharedPreference != null),
        _sharedPreferencesFuture = Future.value(sharedPreference),
        this._logger = logger ?? ((message) => null) {
    _keyValuesChangedSubject
        .listen((pairs) => _logger('[KEYS_CHANGED] pairs=$pairs'));
  }

  ///
  ///
  ///

  ///
  /// Workaround to capture generics
  ///
  static Type _typeOf<T>() => T;

  ///
  /// Get [Observable] from the persistent storage
  ///
  Observable<T> _getObservable<T>(String key, Future<T> get(String key)) {
    return _keyValuesChangedSubject
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
          } else {
            if (T == _typeOf<List<String>>()) {
              return (pair.value as List)?.cast<String>() as T;
            }
            if (T == _typeOf<Set<String>>()) {
              return (pair.value as Set)?.cast<String>() as T;
            }
            return pair.value as T;
          }
        })
        .doOnData((value) => _logger('[OBSERVABLE] key=$key, value=$value'))
        .doOnError((error, stacktrace) =>
            _logger('[OBSERAVBLE] error=$error, stacktrace=$stacktrace'));
  }

  ///
  /// Get value from the persistent storage by [key]
  ///
  Future<T> _get<T>([String key]) {
    return _sharedPreferencesFuture.then((sharedPreferences) {
      if (T == dynamic) {
        return sharedPreferences.get(key);
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
      /// Get all keys
      if (T == _typeOf<Set<String>>() && key == null) {
        return sharedPreferences.getKeys() as T;
      }
    }).then((value) {
      _logger('[READ] key=$key, type=$T => value=$value');
      return value;
    });
  }

  ///
  /// Set [value] associated with [key]
  ///
  Future<bool> _setValue<T>(String key, T value) {
    _triggerKeyChanges(bool result) {
      _logger('[WRITE] key=$key, value=$value, type=$T => result=$result');

      if (result ?? false) {
        _keyValuesChangedSubject.add([_KeyAndValueChanged<T>(key, value)]);
      }
      return result;
    }

    return _sharedPreferencesFuture.then((sharedPreferences) {
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
        return sharedPreferences.setStringList(key, (value as List)?.cast<String>());
      }
    }).then(_triggerKeyChanges);
  }

  ///
  ///
  ///

  ///
  /// Returns a future complete with value true if the persistent storage
  /// contains the given [key].
  ///
  Future<bool> containsKey(String key) => _sharedPreferencesFuture
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
    final SharedPreferences sharedPreferences = await _sharedPreferencesFuture;
    final Set<String> keys = sharedPreferences.getKeys();
    final bool result = await sharedPreferences.clear();
    if (result ?? false) {
      _keyValuesChangedSubject
          .add(keys.map((key) => _KeyAndValueChanged<dynamic>(key, null)));
    }
    return result;
  }

  /// Fetches the latest values from the host platform.
  ///
  /// Use this method to observe modifications that were made in native code
  /// (without using the plugin) while the app is running.
  Future<void> reload() async {
    final SharedPreferences sharedPreferences = await _sharedPreferencesFuture;
    await sharedPreferences.reload();
    _keyValuesChangedSubject.add(
      sharedPreferences
        .getKeys()
        .map((key) => _KeyAndValueChanged(key, sharedPreferences.get(key)))
    );
  }

  /// Always returns true.
  /// On iOS, synchronize is marked deprecated. On Android, we commit every set.
  @deprecated
  Future<bool> commit() => _sharedPreferencesFuture
      .then((sharedPreferences) => sharedPreferences.commit());

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

  ///
  ///
  ///

  @override
  Observable<dynamic> getObservable(String key) => _getObservable(key, get);

  @override
  Observable<bool> getBoolObservable(String key) =>
      _getObservable(key, getBool);

  @override
  Observable<double> getDoubleObservable(String key) =>
      _getObservable(key, getDouble);

  @override
  Observable<int> getIntObservable(String key) => _getObservable(key, getInt);

  @override
  Observable<String> getStringObservable(String key) =>
      _getObservable(key, getString);

  @override
  Observable<List<String>> getStringListObservable(String key) =>
      _getObservable(key, getStringList);
}

///
/// Pair of [key] and [value]
///
class _KeyAndValueChanged<T> {
  final String key;
  final T value;

  const _KeyAndValueChanged(this.key, this.value);

  @override
  String toString() => '_KeyAndValueChanged{key: $key, value: $value}';
}
