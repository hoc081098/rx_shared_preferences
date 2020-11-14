import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../interface/shared_preferences_like.dart';

/// [SharedPreferencesLike]'s implementation by delegating a [SharedPreferences].
class SharedPreferencesAdapter implements SharedPreferencesLike {
  final SharedPreferences _prefs;

  SharedPreferencesAdapter._(this._prefs);

  static Future<T> _wrap<T>(T value) => SynchronousFuture(value);

  @override
  Future<bool> clear() => _prefs.clear();

  @override
  Future<bool> containsKey(String key) => _wrap(_prefs.containsKey(key));

  @override
  Future<dynamic> get(String key) => _wrap(_prefs.get(key));

  @override
  Future<bool> getBool(String key) => _wrap(_prefs.getBool(key));

  @override
  Future<double> getDouble(String key) => _wrap(_prefs.getDouble(key));

  @override
  Future<int> getInt(String key) => _wrap(_prefs.getInt(key));

  @override
  Future<Set<String>> getKeys() => _wrap(_prefs.getKeys());

  @override
  Future<String> getString(String key) => _wrap(_prefs.getString(key));

  @override
  Future<List<String>> getStringList(String key) =>
      _wrap(_prefs.getStringList(key));

  @override
  Future<void> reload() => _prefs.reload();

  @override
  Future<bool> remove(String key) => _prefs.remove(key);

  @override
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  @override
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  @override
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  /// Create [SharedPreferencesAdapter] from [SharedPreferences].
  static FutureOr<SharedPreferencesAdapter> from(
    FutureOr<SharedPreferences> prefsOrFuture,
  ) {
    assert(prefsOrFuture != null);

    return prefsOrFuture is Future<SharedPreferences>
        ? prefsOrFuture.then((p) => SharedPreferencesAdapter._(p))
        : SharedPreferencesAdapter._(prefsOrFuture as SharedPreferences);
  }
}
