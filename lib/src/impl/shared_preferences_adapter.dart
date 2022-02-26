import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rx_storage/rx_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../interface/shared_preferences_like.dart';

/// [SharedPreferencesLike]'s implementation by delegating a [SharedPreferences].
class SharedPreferencesAdapter implements SharedPreferencesLike {
  final SharedPreferences _prefs;

  SharedPreferencesAdapter._(this._prefs);

  static Future<T> _wrap<T>(T value) => SynchronousFuture<T>(value);

  static Future<T> _wrapFutureOr<T>(FutureOr<T> value) =>
      value is Future<T> ? value : SynchronousFuture<T>(value);

  @override
  Future<void> clear([void _]) =>
      _prefs.clear().throwsIfNotSuccess('Cannot clear');

  @override
  Future<bool> containsKey(String key, [void _]) =>
      _wrap(_prefs.containsKey(key));

  @override
  Future<Map<String, Object?>> reload() {
    return _prefs.reload().then((_) {
      return {
        for (final k in _prefs.getKeys()) k: _prefs.get(k),
      };
    });
  }

  @override
  Future<void> remove(String key, [void _]) =>
      _prefs.remove(key).throwsIfNotSuccess('Cannot remove key=$key');

  /// Create [SharedPreferencesAdapter] from [SharedPreferences].
  static FutureOr<SharedPreferencesAdapter> from(
    FutureOr<SharedPreferences> prefsOrFuture,
  ) =>
      prefsOrFuture is Future<SharedPreferences>
          ? prefsOrFuture.then((p) => SharedPreferencesAdapter._(p))
          : SharedPreferencesAdapter._(prefsOrFuture)
              as FutureOr<SharedPreferencesAdapter>;

  @override
  Future<T?> read<T extends Object>(String key, Decoder<T?> decoder, [void _]) {
    var val = _prefs.get(key);
    if (val is List) {
      val = _prefs.getStringList(key);
    }
    return _wrapFutureOr(decoder(val));
  }

  @override
  Future<Map<String, Object?>> readAll([void _]) {
    return _wrap({
      for (final k in _prefs.getKeys()) k: _prefs.get(k),
    });
  }

  @override
  Future<void> write<T extends Object>(
      String key, T? value, Encoder<T?> encoder,
      [void _]) {
    final encodedOrFuture = encoder(value);
    return encodedOrFuture is Future<Object?>
        ? encodedOrFuture.then((encoded) => _write(encoded, key, value))
        : _write(encodedOrFuture, key, value);
  }

  Future<void> _write(Object? encoded, String key, Object? value) {
    assert(encoded is! Future<dynamic>,
        'The actual type of encoded value is ${encoded.runtimeType}');

    if (encoded == null) {
      return remove(key);
    }
    if (encoded is double) {
      return _prefs.setDouble(key, encoded).throwsIfNotSuccess(
          'Cannot set double value: key=$key, value=$value');
    }
    if (encoded is int) {
      return _prefs
          .setInt(key, encoded)
          .throwsIfNotSuccess('Cannot set int value: key=$key, value=$value');
    }
    if (encoded is bool) {
      return _prefs
          .setBool(key, encoded)
          .throwsIfNotSuccess('Cannot set bool value: key=$key, value=$value');
    }
    if (encoded is String) {
      return _prefs.setString(key, encoded).throwsIfNotSuccess(
          'Cannot set String value: key=$key, value=$value');
    }
    if (encoded is List<String>) {
      return _prefs.setStringList(key, encoded).throwsIfNotSuccess(
          'Cannot set List<String> value: key=$key, value=$value');
    }

    throw PlatformException(
      code: SharedPreferencesLike.errorCode,
      message:
          'The encoded value of $value has the unsupported type (${encoded.runtimeType}). '
          'Encoder must return a value of type FutureOr<T> '
          '(where T is a supported type (double, int, bool, String or List<String>))',
    );
  }
}

extension _ThrowsIfNotSuccess on Future<bool> {
  Future<void> throwsIfNotSuccess(String message) {
    return then((isSuccessful) {
      if (!isSuccessful) {
        throw PlatformException(
          code: SharedPreferencesLike.errorCode,
          message: message,
        );
      }
    });
  }
}
