import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

/// Stores encoded strings in [FlutterSecureStorage]; encoded nulls remove keys.
///
/// Other value types need an encoder and decoder that use a string representation.
final class FlutterSecureStorageAdapter implements SharedPreferencesLike {
  final FlutterSecureStorage _secureStorage;

  /// Uses the supplied storage instance and its platform-specific options.
  const FlutterSecureStorageAdapter(this._secureStorage);

  @override
  Future<bool> containsKey(String key, [void options]) =>
      _secureStorage.containsKey(key: key);

  @override
  Future<T?> read<T extends Object>(
    String key,
    Decoder<T?> decoder, [
    void options,
  ]) => _secureStorage.read(key: key).then(decoder);

  @override
  Future<Map<String, Object?>> readAll(
    EntryDecoder<String> decoder, [
    void options,
  ]) => _secureStorage.readAll().then((values) {
    // Snapshot entries before decoders can mutate the underlying store.
    final entries = values.entries.toList(growable: false);

    return Future.wait(
      entries.map(
        (entry) => Future<Object?>.sync(
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
  Future<void> write<T extends Object>(
    String key,
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
          'Encoder must return a String or null, synchronously or asynchronously. '
          'Received ${encoded.runtimeType}.',
    );
  }

  @override
  Future<Map<String, Object?>> reload() => _secureStorage.readAll();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const secureStorage = FlutterSecureStorage();
  final adapter = FlutterSecureStorageAdapter(secureStorage);
  // Leave operation logging disabled because log events include stored values.
  final rxPrefs = RxSharedPreferences.custom(adapter);

  // Built-in typed helpers must match the adapter's string representation.
  const accessTokenKey = 'access_token';
  final subscription = rxPrefs
      .getStringStream(accessTokenKey)
      .listen((value) => debugPrint('Access token present: ${value != null}'));

  try {
    await delay(300);

    await rxPrefs.setString(accessTokenKey, 'example-access-token');
    await delay(300);

    await rxPrefs.remove(accessTokenKey);
    await delay(300);
  } finally {
    await subscription.cancel();
    await rxPrefs.dispose();
  }
}
