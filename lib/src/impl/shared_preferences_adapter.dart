import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rx_storage/rx_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../interface/shared_preferences_like.dart';

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
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Future<T> read<T>(String key, Decoder<T> decoder, [void _]) {
    var val = _prefs.get(key);
    if (val is List) {
      val = _prefs.getStringList(key);
    }
    return _wrap(decoder(val));
  }

  @override
  Future<Map<String, dynamic>> readAll([void _]) {
    return _wrap({
      for (final k in _prefs.getKeys()) k: _prefs.get(k),
    });
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Future<bool> write<T>(String key, T value, Encoder<T> encoder, [void _]) {
    final val = encoder(value);

    if (val == null) {
      return _prefs.remove(key);
    }
    if (val is double) {
      return _prefs.setDouble(key, val);
    }
    if (val is int) {
      return _prefs.setInt(key, val);
    }
    if (val is bool) {
      return _prefs.setBool(key, val);
    }
    if (val is String) {
      return _prefs.setString(key, val);
    }
    if (val is List<String>) {
      return _prefs.setStringList(key, val);
    }

    throw StateError('Value $val has type ${val.runtimeType} is not supported. '
        'Encoder must return a value of a supported type, eg. double, int, bool, String or List<String>');
  }
}
