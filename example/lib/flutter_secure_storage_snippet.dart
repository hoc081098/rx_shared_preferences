import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rx_shared_preferences/src/impl/real_rx_shared_preferences.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

final class FlutterSecureStorageAdapter
    implements Storage<String, void>, SharedPreferencesLike {
  final FlutterSecureStorage _secureStorage;

  FlutterSecureStorageAdapter(this._secureStorage);

  @override
  Future<bool> containsKey(String key, [void options]) =>
      _secureStorage.containsKey(key: key);

  @override
  Future<T?> read<T extends Object>(String key,
      Decoder<T?> decoder, [
        void options,
      ]) => _secureStorage.read(key: key).then(decoder);

  @override
  Future<Map<String, Object?>> readAll(EntryDecoder<String> decoder, [
    void options,
  ]) =>
      _secureStorage.readAll().then((values) {
        final entries = values.entries.toList(growable: false);

        return Future.wait(
          entries.map(
                (entry) =>
                Future<Object?>.sync(
                      () => decoder(entry.key, entry.value),
                ).then((value) => MapEntry(entry.key, value)),
          ),
          eagerError: true,
        ).then((decoded) => Map<String, Object?>.fromEntries(decoded));
      });

  @override
  Future<void> clear([void options]) => _secureStorage.deleteAll();

  @override
  Future<void> remove(String key, [void options]) =>
      _secureStorage.delete(key: key);

  @override
  Future<void> write<T extends Object>(String key,
      T? value,
      Encoder<T?> encoder, [
        void options,
      ]) {
    final encodedOrFuture = encoder(value);
    return encodedOrFuture is Future<Object?>
        ? encodedOrFuture.then((encoded) => _write(key: key, encoded: encoded))
        : _write(key: key, encoded: encodedOrFuture);
  }

  Future<void> _write({required String key, Object? encoded}) {
    assert(
    encoded is! Future<dynamic>,
    'The actual type of encoded value is ${encoded.runtimeType}',
    );

    if (encoded == null) {
      return _secureStorage.delete(key: key);
    }
    if (encoded is String) {
      return _secureStorage.write(key: key, value: encoded);
    }
    throw PlatformException(
      code: SharedPreferencesLike.errorCode,
      message:
      'The encoded value of $encoded has the unsupported type (${encoded
          .runtimeType}). '
          'Encoder must return a FutureOr<String>',
    );
  }

  @override
  Future<Map<String, Object?>> reload() => _secureStorage.readAll();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Default secure storage - Uses RSA OAEP + AES-GCM (recommended)
  final secureStorage = FlutterSecureStorage();
  final adapter = FlutterSecureStorageAdapter(secureStorage);
  final rxPrefs = RealRxSharedPreferences(
    adapter,
    kReleaseMode ? null : RxSharedPreferencesDefaultLogger(),
        () {},
  );

  final subscriptions = CompositeSubscription();

  // Because FlutterSecureStorage only supports String values, we only use String-type methods/extensions.
  const accessTokenKey = 'access_token';
  rxPrefs
      .getStringStream(accessTokenKey)
      .listen((value) => print('Access token changed: $value'))
      .addTo(subscriptions);

  rxPrefs.setString(accessTokenKey, 'updated-access-token');
  rxPrefs.remove(accessTokenKey);
}
