import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

///
/// Get [Observable]s by key from [SharedPreferences]
///
abstract class IRxSharedPreferences {
  Observable<dynamic> getObservable(String key);

  Observable<bool> getBoolObservable(String key);

  Observable<double> getDoubleObservable(String key);

  Observable<int> getIntObservable(String key);

  Observable<String> getStringObservable(String key);

  Observable<List<String>> getStringListObservable(String key);
}

///
///
///
class RxSharedPreferences implements IRxSharedPreferences {
  // ignore: close_sinks
  final PublishSubject<Set<String>> _keyChanges = PublishSubject<Set<String>>();
  final Future<SharedPreferences> _sharedPreferencesFuture;

  RxSharedPreferences(FutureOr<SharedPreferences> sharedPreference)
      : _sharedPreferencesFuture = Future.value(sharedPreference);

  Future<bool> clear() async {
    final SharedPreferences sharedPreferences = await _sharedPreferencesFuture;
    final Set<String> keys = sharedPreferences.getKeys();
    final bool result = await sharedPreferences.clear();
    if (result ?? false) {
      _keyChanges.add(keys);
    }
    return result;
  }

  @deprecated
  Future<bool> commit() {
    return _sharedPreferencesFuture.then((shared) => shared.commit());
  }

  Future<bool> containsKey(String key) {
    return _sharedPreferencesFuture.then((shared) => shared.containsKey(key));
  }

  Future<dynamic> get(String key) {
    return _sharedPreferencesFuture.then((shared) => shared.get(key));
  }

  Future<bool> getBool(String key) {
    return _sharedPreferencesFuture.then((shared) => shared.getBool(key));
  }

  Future<double> getDouble(String key) {
    return _sharedPreferencesFuture.then((shared) => shared.getDouble(key));
  }

  Future<int> getInt(String key) {
    return _sharedPreferencesFuture.then((shared) => shared.getInt(key));
  }

  Future<Set<String>> getKeys() {
    return _sharedPreferencesFuture.then((shared) => shared.getKeys());
  }

  Future<String> getString(String key) {
    return _sharedPreferencesFuture.then((shared) => shared.getString(key));
  }

  Future<List<String>> getStringList(String key) {
    return _sharedPreferencesFuture.then((shared) => shared.getStringList(key));
  }

  Future<bool> remove(String key) {
    return _sharedPreferencesFuture
        .then((shared) => shared.remove(key))
        .then((result) => _triggerKeyChanges(<String>{key}, result));
  }

  Future<bool> setBool(String key, bool value) {
    return _sharedPreferencesFuture
        .then((shared) => shared.setBool(key, value))
        .then((result) => _triggerKeyChanges(<String>{key}, result));
  }

  Future<bool> setDouble(String key, double value) {
    return _sharedPreferencesFuture
        .then((shared) => shared.setDouble(key, value))
        .then((result) => _triggerKeyChanges(<String>{key}, result));
  }

  Future<bool> setInt(String key, int value) {
    return _sharedPreferencesFuture
        .then((shared) => shared.setInt(key, value))
        .then((result) => _triggerKeyChanges(<String>{key}, result));
  }

  Future<bool> setString(String key, String value) {
    return _sharedPreferencesFuture
        .then((shared) => shared.setString(key, value))
        .then((result) => _triggerKeyChanges(<String>{key}, result));
  }

  Future<bool> setStringList(String key, List<String> value) {
    return _sharedPreferencesFuture
        .then((shared) => shared.setStringList(key, value))
        .then((result) => _triggerKeyChanges(<String>{key}, result));
  }

  bool _triggerKeyChanges(Set<String> keys, bool result) {
    if (result ?? false) {
      _keyChanges.add(keys);
    }
    return result;
  }

  Observable<T> _get$<T>(String key, Future<T> get(String key)) {
    return _keyChanges
        .where((keys) => keys.contains(key))
        .startWith(null)
        .asyncMap((_) => get(key));
  }

  @override
  Observable<dynamic> getObservable(String key) {
    return _get$(key, get);
  }

  @override
  Observable<bool> getBoolObservable(String key) {
    return _get$(key, getBool);
  }

  @override
  Observable<double> getDoubleObservable(String key) {
    return _get$(key, getDouble);
  }

  @override
  Observable<int> getIntObservable(String key) {
    return _get$(key, getInt);
  }

  @override
  Observable<String> getStringObservable(String key) {
    return _get$(key, getString);
  }

  @override
  Observable<List<String>> getStringListObservable(String key) {
    return _get$(key, getStringList);
  }
}
