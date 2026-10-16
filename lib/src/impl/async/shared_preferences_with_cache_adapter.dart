import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rx_storage/rx_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../interface/shared_preferences_like.dart';

/// [SharedPreferencesLike]'s implementation by delegating a [SharedPreferencesWithCache].
class SharedPreferencesWithCacheAdapter implements SharedPreferencesLike {
  final SharedPreferencesWithCache _prefsWithCache;

  SharedPreferencesWithCacheAdapter._(this._prefsWithCache);

  static Future<T> _wrap<T>(T value) => SynchronousFuture<T>(value);

  static Future<T> _wrapFutureOr<T>(FutureOr<T> value) =>
      value is Future<T> ? value : SynchronousFuture<T>(value);

  /// Create [SharedPreferencesAdapter] from [SharedPreferences].
  static FutureOr<SharedPreferencesWithCacheAdapter> from(
    FutureOr<SharedPreferencesWithCache> prefsOrFuture,
  ) =>
      prefsOrFuture is Future<SharedPreferencesWithCache>
          ? prefsOrFuture.then((p) => SharedPreferencesWithCacheAdapter._(p))
          : SharedPreferencesWithCacheAdapter._(prefsOrFuture)
              as FutureOr<SharedPreferencesWithCacheAdapter>;

  @override
  Future<void> clear([void _]) => _prefsWithCache.clear();

  @override
  Future<bool> containsKey(String key, [void _]) =>
      _wrap(_prefsWithCache.containsKey(key));

  @override
  Future<Map<String, Object?>> reload() =>
      _prefsWithCache.reloadCache().then((_) => _getAllFromPrefs());

  @override
  Future<void> remove(String key, [void _]) => _prefsWithCache.remove(key);

  @override
  Future<T?> read<T extends Object>(String key, Decoder<T?> decoder,
          [void _]) =>
      _wrapFutureOr(decoder(_getFromPrefs(key)));

  @override
  Future<Map<String, Object?>> readAll([void _]) => _wrap(_getAllFromPrefs());

  @override
  Future<void> write<T extends Object>(
      String key, T? value, Encoder<T?> encoder,
      [void _]) {
    final encodedOrFuture = encoder(value);
    return encodedOrFuture is Future<Object?>
        ? encodedOrFuture.then((encoded) => _write(encoded, key, value))
        : _write(encodedOrFuture, key, value);
  }

  Object? _getFromPrefs(String key) {
    final val = _prefsWithCache.get(key);
    return val is List ? _prefsWithCache.getStringList(key) : val;
  }

  Map<String, Object?> _getAllFromPrefs() {
    return {
      for (final k in _prefsWithCache.keys) k: _getFromPrefs(k),
    };
  }

  Future<void> _write(Object? encoded, String key, Object? value) {
    assert(encoded is! Future<dynamic>,
        'The actual type of encoded value is ${encoded.runtimeType}');

    if (encoded == null) {
      return remove(key);
    }
    if (encoded is double) {
      return _prefsWithCache.setDouble(key, encoded);
    }
    if (encoded is int) {
      return _prefsWithCache.setInt(key, encoded);
    }
    if (encoded is bool) {
      return _prefsWithCache.setBool(key, encoded);
    }
    if (encoded is String) {
      return _prefsWithCache.setString(key, encoded);
    }
    if (encoded is List<String>) {
      return _prefsWithCache.setStringList(key, encoded);
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
