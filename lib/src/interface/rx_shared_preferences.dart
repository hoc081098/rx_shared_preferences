import 'dart:async';

import 'package:rx_storage/rx_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../rx_shared_preferences.dart';
import '../impl/real_rx_shared_preferences.dart';
import '../impl/shared_preferences_adapter.dart';
import 'shared_preferences_like.dart';

/// Get [Stream]s by key from persistent storage.
abstract class RxSharedPreferences extends RxStorage<String>
    implements SharedPreferencesLike {
  static RxStorage _defaultInstance;

  /// Return default singleton instance.
  /// Custom logger via [RxSharedPreferencesConfigs.logger].
  factory RxSharedPreferences.getInstance() =>
      _defaultInstance ??= RxSharedPreferences(
        SharedPreferences.getInstance(),
        RxSharedPreferencesConfigs.logger,
        () => _defaultInstance = null,
      );

  /// Construct a [RxSharedPreferences] with [SharedPreferences] and optional [Logger]
  factory RxSharedPreferences(
    FutureOr<SharedPreferences> prefsOrFuture, [
    Logger logger,
    void Function() onDispose,
  ]) =>
      RealRxSharedPreferences(
        SharedPreferencesAdapter.from(prefsOrFuture),
        logger,
        onDispose,
      );
}
