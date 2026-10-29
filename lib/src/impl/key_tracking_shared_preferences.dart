import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import '../interface/shared_preferences_like.dart';
import '../utils/identity.dart';

/// Wraps a preferences adapter and tracks keys for reload notifications.
///
/// An async adapter's next read already sees external changes. Keep keys from
/// earlier reads and successful writes, including reads that finish during
/// reload. Cached adapters also contribute their pre-reload keys.
///
/// Reads remember raw keys even if decoding fails. Writes change tracking only
/// after persistence succeeds, using the encoded value to identify removals.
///
/// [reload] owns key collection and reconciliation together. It returns raw
/// values and removed keys; the reactive wrapper publishes the notifications.
final class KeyTrackingSharedPreferences implements Storage<String, void> {
  final SharedPreferencesLike _delegate;
  final _knownKeys = <String>{};

  KeyTrackingSharedPreferences._(this._delegate);

  /// Wraps an adapter without making synchronous initialization asynchronous.
  static FutureOr<KeyTrackingSharedPreferences> from(
    FutureOr<SharedPreferencesLike> storage,
  ) => storage is Future<SharedPreferencesLike>
      ? storage.then(KeyTrackingSharedPreferences._)
      : KeyTrackingSharedPreferences._(storage);

  @override
  Future<bool> containsKey(String key, [void options]) =>
      _delegate.containsKey(key, options);

  @override
  Future<T?> read<T extends Object>(
    String key,
    Decoder<T?> decoder, [
    void options,
  ]) => _delegate.read<T>(key, (raw) {
    if (raw != null) _knownKeys.add(key);
    return decoder(raw);
  }, options);

  @override
  Future<Map<String, Object?>> readAll(
    EntryDecoder<String> decoder, [
    void options,
  ]) => _delegate.readAll((key, raw) {
    _knownKeys.add(key);
    return decoder(key, raw);
  }, options);

  @override
  Future<void> write<T extends Object>(
    String key,
    T? value,
    Encoder<T?> encoder, [
    void options,
  ]) {
    var removesKey = false;
    Object? captureEncoded(Object? encoded) {
      removesKey = encoded == null;
      return encoded;
    }

    return _delegate
        .write<T>(key, value, (value) {
          final encoded = encoder(value);
          return encoded is Future<Object?>
              ? encoded.then(captureEncoded)
              : captureEncoded(encoded);
        }, options)
        .then((_) {
          if (removesKey) {
            _knownKeys.remove(key);
          } else {
            _knownKeys.add(key);
          }
        });
  }

  @override
  Future<void> remove(String key, [void options]) =>
      _delegate.remove(key, options).then((_) => _knownKeys.remove(key));

  @override
  Future<void> clear([void options]) =>
      _delegate.clear(options).then((_) => _knownKeys.clear());

  /// Reloads raw values and reports keys removed since earlier operations.
  ///
  /// Read cached keys into the live tracked set first. Reads that complete during
  /// either await add keys; successful local removals delete keys. Reconcile
  /// only after reload succeeds, without another await between diff and reset.
  Future<({Map<String, Object?> values, Set<String> removedKeys})>
  reload() async {
    await readAll(identityEntryDecoder);
    final values = await _delegate.reload();
    final currentKeys = values.keys.toSet();
    final removedKeys = _knownKeys.difference(currentKeys);
    _knownKeys
      ..clear()
      ..addAll(currentKeys);
    return (values: values, removedKeys: removedKeys);
  }
}
