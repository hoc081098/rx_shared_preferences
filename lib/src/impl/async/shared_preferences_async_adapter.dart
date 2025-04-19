import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:rx_storage/rx_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../interface/shared_preferences_like.dart';

/// [SharedPreferencesLike]'s implementation by delegating a [SharedPreferencesAsync].
@experimental
class SharedPreferencesAsyncAdapter implements SharedPreferencesLike {
  final SharedPreferencesAsync _prefsAsync;

  /// Construct a [SharedPreferencesAdapter] with [SharedPreferencesAsync].
  SharedPreferencesAsyncAdapter(this._prefsAsync);

  @override
  Future<void> clear([void _]) => _prefsAsync.clear();

  @override
  Future<bool> containsKey(String key, [void _]) =>
      _prefsAsync.containsKey(key);

  @override
  Future<Map<String, Object?>> reload() => _prefsAsync.getAll();

  @override
  Future<void> remove(String key, [void _]) => _prefsAsync.remove(key);

  @override
  Future<T?> read<T extends Object>(String key, Decoder<T?> decoder,
          [void _]) =>
      _prefsAsync.getAll(allowList: {key}).then((map) => decoder(map[key]));

  @override
  Future<Map<String, Object?>> readAll([void _]) => _prefsAsync.getAll();

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
      return _prefsAsync.setDouble(key, encoded);
    }
    if (encoded is int) {
      return _prefsAsync.setInt(key, encoded);
    }
    if (encoded is bool) {
      return _prefsAsync.setBool(key, encoded);
    }
    if (encoded is String) {
      return _prefsAsync.setString(key, encoded);
    }
    if (encoded is List<String>) {
      return _prefsAsync.setStringList(key, encoded);
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
