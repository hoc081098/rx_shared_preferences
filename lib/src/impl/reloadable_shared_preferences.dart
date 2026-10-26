import 'dart:async';

import 'package:rx_storage/rx_storage.dart';

import '../interface/shared_preferences_like.dart';

/// Tracks known keys so reload can notify observers of external removals.
///
/// An async adapter's next read already sees external changes. Keep keys from
/// earlier reads and successful writes until reload reconciles them with the
/// backing store. Cached adapters also contribute their pre-reload keys.
final class ReloadableSharedPreferences implements SharedPreferencesLike {
  final SharedPreferencesLike _delegate;
  final _knownKeys = <String>{};

  ReloadableSharedPreferences._(this._delegate);

  /// Wraps an adapter without making synchronous initialization asynchronous.
  static FutureOr<ReloadableSharedPreferences> from(
    FutureOr<SharedPreferencesLike> storage,
  ) => storage is Future<SharedPreferencesLike>
      ? storage.then(ReloadableSharedPreferences._)
      : ReloadableSharedPreferences._(storage);

  /// Returns previously known keys together with the current adapter's keys.
  Future<Set<String>> readKeysBeforeReload() async {
    final keys = Set<String>.of(_knownKeys);
    final current = await readAll((_, raw) => raw);
    return keys..addAll(current.keys);
  }

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

  @override
  Future<Map<String, Object?>> reload() {
    final previousKeys = Set<String>.of(_knownKeys);
    return _delegate.reload().then((values) {
      _knownKeys
        ..removeAll(previousKeys.difference(values.keys.toSet()))
        ..addAll(values.keys);
      return values;
    });
  }
}
