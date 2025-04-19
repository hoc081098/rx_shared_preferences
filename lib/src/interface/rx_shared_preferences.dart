import 'dart:async';

import 'package:meta/meta.dart';
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
const legacyRxSharedPreferencesApi = _LegacyRxSharedPreferencesApi();

/// Get [Stream]s by key from persistent storage.
abstract class RxSharedPreferences extends RxStorage<String, void>
    implements SharedPreferencesLike {
  @legacyRxSharedPreferencesApi
  static RxSharedPreferences? _defaultInstance;

  /// Return default singleton instance.
  /// Custom logger via [RxSharedPreferencesConfigs.logger].
  ///
  /// This is a legacy API. For new code, consider [RxSharedPreferences.getAsyncInstance]
  /// or [RxSharedPreferences.getWithCacheInstance].
  @legacyRxSharedPreferencesApi
  factory RxSharedPreferences.getInstance() =>
      _defaultInstance ??= RxSharedPreferences(
        SharedPreferences.getInstance(),
        RxSharedPreferencesConfigs.logger,
        () => _defaultInstance = null,
      );

  /// Construct a [RxSharedPreferences] with [SharedPreferences] and optional [Logger].
  ///
  /// This is a legacy API. For new code, consider [RxSharedPreferences.async]
  /// or [RxSharedPreferences.withCache].
  @legacyRxSharedPreferencesApi
  factory RxSharedPreferences(
    FutureOr<SharedPreferences> prefsOrFuture, [
    RxSharedPreferencesLogger? logger,
    void Function()? onDispose,
  ]) =>
      RealRxSharedPreferences(
        SharedPreferencesAdapter.from(prefsOrFuture),
        logger,
        onDispose,
      );

  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  static RxSharedPreferences? _defaultAsyncInstance;
  static RxSharedPreferences? _defaultWithCacheInstance;

  /// Return default singleton instance using [SharedPreferencesAsync].
  /// Custom logger via [RxSharedPreferencesConfigs.logger].
  factory RxSharedPreferences.getAsyncInstance() =>
      _defaultAsyncInstance ??= RxSharedPreferences.async(
        SharedPreferencesAsync(),
        RxSharedPreferencesConfigs.logger,
        () => _defaultAsyncInstance = null,
      );

  /// Return default singleton instance using [SharedPreferencesWithCache].
  /// Custom logger via [RxSharedPreferencesConfigs.logger].
  factory RxSharedPreferences.getWithCacheInstance({
    SharedPreferencesWithCacheOptions cacheOptions =
        const SharedPreferencesWithCacheOptions(),
  }) =>
      _defaultWithCacheInstance ??= RxSharedPreferences.withCache(
        SharedPreferencesWithCache.create(cacheOptions: cacheOptions),
        RxSharedPreferencesConfigs.logger,
        () => _defaultWithCacheInstance = null,
      );

  /// Construct a [RxSharedPreferences] with [SharedPreferencesAsync] and optional [Logger].
  @experimental
  factory RxSharedPreferences.async(
    SharedPreferencesAsync prefsAsync, [
    RxSharedPreferencesLogger? logger,
    void Function()? onDispose,
  ]) =>
      RealRxSharedPreferences(
        SharedPreferencesAsyncAdapter(prefsAsync),
        logger,
        onDispose,
      );

  /// Construct a [RxSharedPreferences] with [SharedPreferencesWithCache] and optional [Logger].
  @experimental
  factory RxSharedPreferences.withCache(
    FutureOr<SharedPreferencesWithCache> prefsWithCache, [
    RxSharedPreferencesLogger? logger,
    void Function()? onDispose,
  ]) =>
      RealRxSharedPreferences(
        SharedPreferencesWithCacheAdapter.from(prefsWithCache),
        logger,
        onDispose,
      );
}
