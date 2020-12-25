import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rx_storage/rx_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../interface/shared_preferences_like.dart';

/// [SharedPreferencesLike]'s implementation by delegating a [SharedPreferences].
class SharedPreferencesAdapter implements SharedPreferencesLike {
  final SharedPreferences _prefs;
  final _stringList = (<T>() => T)<List<String>>();

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

  @override
  Future<T> read<T>(String key, Encoder<T> decoder) {
    if (T == dynamic) {
      return _prefs.get(key);
    }
    if (T == double) {
      return _wrap(_prefs.getDouble(key) as dynamic);
    }
    if (T == int) {
      return _wrap(_prefs.getInt(key) as dynamic);
    }
    if (T == bool) {
      return _wrap(_prefs.getBool(key) as dynamic);
    }
    if (T == String) {
      return _wrap(_prefs.getString(key) as dynamic);
    }
    if (T == _stringList) {
      return _wrap(_prefs.getStringList(key) as dynamic);
    }
    throw StateError('Unhandled type $T');
  }

  @override
  Future<Map<String, dynamic>> readAll() => _wrap({
        for (final k in _prefs.getKeys()) k: _prefs.get(k),
      });

  @override
  Future<bool> write<T>(String key, T value, Encoder<T> encoder) {
    final dynamicVal = value as dynamic;

    if (T == double) {
      return _prefs.setDouble(key, dynamicVal);
    }
    if (T == int) {
      return _prefs.setInt(key, dynamicVal);
    }
    if (T == bool) {
      return _prefs.setBool(key, dynamicVal);
    }
    if (T == String) {
      return _prefs.setString(key, dynamicVal);
    }
    if (T == _stringList) {
      return _prefs.setStringList(key, dynamicVal);
    }

    throw StateError('Unhandled type $T');
  }
}
