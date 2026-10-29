import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import '../interface/shared_preferences_like.dart';

/// Wraps a preferences adapter and tracks keys for reload notifications.
///
/// An async adapter's next read already sees external changes. Keep keys from
/// earlier reads and successful writes, including reads that finish during
/// reload. Cached adapters also contribute their pre-reload keys.
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
  ]) => _delegate.write<T>(key, value, encoder, options).then((_) {
    _knownKeys.add(key);
  });

  @override
  Future<void> remove(String key, [void options]) =>
      _delegate.remove(key, options).then((_) => _knownKeys.remove(key));

  @override
  Future<void> clear([void options]) =>
      _delegate.clear(options).then((_) => _knownKeys.clear());

  /// Reloads raw values and reports keys removed since earlier operations.
  ///
  /// Include keys learned while either storage read was pending, then reconcile
  /// the tracked keys without another await. Failed reloads retain known keys
  /// so that a later successful reload can still report their removal.
  Future<({Map<String, Object?> values, Set<String> removedKeys})>
  reload() async {
    final previousKeys = Set<String>.of(_knownKeys);
    final current = await readAll((_, raw) => raw);
    previousKeys.addAll(current.keys);

    final values = await _delegate.reload();
    final removedKeys = {...previousKeys, ..._knownKeys}.difference(
      values.keys.toSet(),
    );
    _knownKeys
      ..removeAll(removedKeys)
      ..addAll(values.keys);
    return (values: values, removedKeys: removedKeys);
  }
}
