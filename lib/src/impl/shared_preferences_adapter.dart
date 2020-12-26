import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rx_storage/rx_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../interface/shared_preferences_like.dart';

final _stringList = (<T>() => T)<List<String>>();

/// [SharedPreferencesLike]'s implementation by delegating a [SharedPreferences].
class SharedPreferencesAdapter implements SharedPreferencesLike {
  final SharedPreferences _prefs;

  SharedPreferencesAdapter._(this._prefs);

  static Future<T> _wrap<T>(T value) => SynchronousFuture<T>(value);

  @override
  Future<bool> clear([void _]) => _prefs.clear();

  @override
  Future<bool> containsKey(String key, [void _]) =>
      _wrap(_prefs.containsKey(key));

  @override
  Future<void> reload() => _prefs.reload();

  @override
  Future<bool> remove(String key, [void _]) => _prefs.remove(key);

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
  Future<T> read<T>(String key, Decoder<T> decoder, [void _]) {
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

    return _wrap(decoder(_prefs.getString(key)));
  }

  @override
  Future<Map<String, dynamic>> readAll([void _]) {
    return _wrap({
      for (final k in _prefs.getKeys()) k: _prefs.get(k),
    });
  }

  @override
  Future<bool> write<T>(String key, T value, Encoder<T> encoder, [void _]) {
    if (value == null) {
      return _prefs.remove(key);
    }

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

    return _prefs.setString(
      key,
      encoder(dynamicVal) as String,
    );
  }
}
