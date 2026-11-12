import 'dart:async';

import 'package:rx_storage/rx_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/global_config.dart';
import '../impl/async/shared_preferences_async_adapter.dart';
import '../impl/async/shared_preferences_with_cache_adapter.dart';
import '../impl/legacy/shared_preferences_adapter.dart';
import '../impl/real_rx_shared_preferences.dart';
import '../logger/logger.dart';
import 'shared_preferences_like.dart';

class _LegacyRxSharedPreferencesApi {
  const _LegacyRxSharedPreferencesApi();
}

/// This is used to mark legacy API methods in the `RxSharedPreferences` class.
///
/// @nodoc
const legacyRxSharedPreferencesApi = _LegacyRxSharedPreferencesApi();

/// Get [Stream]s by key from persistent storage.
///
/// After a successful [write], existing key streams emit the original input.
/// The encoder controls the stored value. An encoded `null` removes the key,
/// but the write notification still carries the input value.
///
/// Implement this contract to provide a custom reactive implementation.
abstract interface class RxSharedPreferences
    implements RxStorage<String, void>, SharedPreferencesLike {
  //////////////////////////////////////////////////////////////////////////////
  // Instance constructors
  //////////////////////////////////////////////////////////////////////////////

  /// Wraps [SharedPreferencesAsync], which reads without a local cache.
  ///
  /// The optional [logger] defaults to `null`, disabling operation and stream
  /// logging. [onDispose] runs once when this wrapper is disposed.
  factory RxSharedPreferences.async(
    SharedPreferencesAsync prefsAsync, [
    RxSharedPreferencesLogger? logger,
    void Function()? onDispose,
  ]) => RxSharedPreferences.custom(
    SharedPreferencesAsyncAdapter(prefsAsync),
    logger,
    onDispose,
  );

  /// Wraps [SharedPreferencesWithCache] or its initialization future.
  ///
  /// Reads use the adapter's local cache, but still return [Future]s.
  /// Call [reload] to refresh the cache and notify streams of external changes.
  factory RxSharedPreferences.cached(
    FutureOr<SharedPreferencesWithCache> prefsWithCache, [
    RxSharedPreferencesLogger? logger,
    void Function()? onDispose,
  ]) => RxSharedPreferences.custom(
    SharedPreferencesWithCacheAdapter.from(prefsWithCache),
    logger,
    onDispose,
  );

  /// Wraps a custom [SharedPreferencesLike] adapter or its initialization future.
  ///
  /// The optional [logger] defaults to `null`, disabling operation and stream
  /// logging. [onDispose] runs once when this wrapper is disposed.
  /// Changes made directly through the adapter require [reload] to notify streams.
  factory RxSharedPreferences.custom(
    FutureOr<SharedPreferencesLike> prefsLikeOrFuture, [
    RxSharedPreferencesLogger? logger,
    void Function()? onDispose,
  ]) => RealRxSharedPreferences(prefsLikeOrFuture, logger, onDispose);

  //////////////////////////////////////////////////////////////////////////////
  // Default singletons
  //////////////////////////////////////////////////////////////////////////////

  static RxSharedPreferences? _defaultAsyncInstance;
  static RxSharedPreferences? _defaultCachedInstance;

  /// Return default singleton instance using [SharedPreferencesAsync].
  /// Uses [RxSharedPreferencesConfigs.logger] on first access.
  ///
  /// [options] is used only on first access, until the instance is disposed.
  factory RxSharedPreferences.getAsyncInstance({
    SharedPreferencesOptions options = const SharedPreferencesOptions(),
  }) => _defaultAsyncInstance ??= RxSharedPreferences.async(
    SharedPreferencesAsync(options: options),
    RxSharedPreferencesConfigs.logger,
    () => _defaultAsyncInstance = null,
  );

  /// Return default singleton instance using [SharedPreferencesWithCache].
  /// Uses [RxSharedPreferencesConfigs.logger] on first access.
  ///
  /// [sharedPreferencesOptions], [cacheOptions] and [cache] are used
  /// only on first access, until the instance is disposed.
  /// [cache] must be mutable; initialization refreshes its contents from storage.
  factory RxSharedPreferences.getCachedInstance({
    SharedPreferencesOptions sharedPreferencesOptions =
        const SharedPreferencesOptions(),
    required SharedPreferencesWithCacheOptions cacheOptions,
    Map<String, Object?>? cache,
  }) => _defaultCachedInstance ??= RxSharedPreferences.cached(
    SharedPreferencesWithCache.create(
      sharedPreferencesOptions: sharedPreferencesOptions,
      cacheOptions: cacheOptions,
      cache: cache,
    ),
    RxSharedPreferencesConfigs.logger,
    () => _defaultCachedInstance = null,
  );

  //////////////////////////////////////////////////////////////////////////////
  // Reload
  //////////////////////////////////////////////////////////////////////////////

  /// Refreshes storage and returns the snapshot used to notify key streams.
  ///
  /// Without [decoder], the returned map and notifications contain raw values.
  /// Otherwise, [decoder] converts each `(key, raw)` entry to its logical value,
  /// synchronously or asynchronously. Use the same logical type for each key as
  /// its writes and key streams. Per-key [observe] decoders are not reapplied to
  /// reload notifications.
  ///
  /// Entries are captured before invoking decoders, which may run concurrently.
  /// A decoded `null` retains its key in the returned map. Keys removed since
  /// earlier reads or writes through this wrapper emit `null` on their key
  /// streams and are not passed to [decoder].
  ///
  /// Notifications are published only after all entries decode successfully.
  /// The first decoder error completes the future with that error while other
  /// decoders keep running. No reload notifications are published on failure,
  /// and removed keys remain tracked for retry. The underlying cache may already
  /// have refreshed and is not rolled back.
  ///
  /// Reloads run in order with [clear], while per-key writes may interleave.
  /// A reload snapshot can therefore notify streams after a newer local write.
  /// A decoder must not await [reload] or [clear] on this same instance because
  /// those operations wait for the current reload to finish.
  @override
  Future<Map<String, Object?>> reload([EntryDecoder<String>? decoder]);

  //////////////////////////////////////////////////////////////////////////////
  // Legacy API
  //////////////////////////////////////////////////////////////////////////////

  @legacyRxSharedPreferencesApi
  static RxSharedPreferences? _defaultInstance;

  /// Returns the legacy [SharedPreferences] singleton wrapper.
  ///
  /// Uses [RxSharedPreferencesConfigs.logger] on first access.
  /// Changing the underlying storage may require migrating existing data.
  @Deprecated(
    'Use getAsyncInstance or getCachedInstance for new code. '
    'Migrate existing data when changing storage.',
  )
  @legacyRxSharedPreferencesApi
  factory RxSharedPreferences.getInstance() =>
      _defaultInstance ??= RxSharedPreferences(
        SharedPreferences.getInstance(),
        RxSharedPreferencesConfigs.logger,
        () => _defaultInstance = null,
      );

  /// Wraps the legacy [SharedPreferences] storage.
  ///
  /// Changing the underlying storage may require migrating existing data.
  @Deprecated(
    'Use RxSharedPreferences.async or RxSharedPreferences.cached for new code. '
    'Migrate existing data when changing storage.',
  )
  @legacyRxSharedPreferencesApi
  factory RxSharedPreferences(
    FutureOr<SharedPreferences> prefsOrFuture, [
    RxSharedPreferencesLogger? logger,
    void Function()? onDispose,
  ]) => RxSharedPreferences.custom(
    SharedPreferencesAdapter.from(prefsOrFuture),
    logger,
    onDispose,
  );
}
