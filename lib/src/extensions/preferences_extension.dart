import 'package:shared_preferences/shared_preferences.dart';

import '../config/global_config.dart';
import '../impl/legacy/shared_preferences_adapter.dart';
import '../interface/rx_shared_preferences.dart';

final _instances = <SharedPreferences, RxSharedPreferences>{};

/// Provides the legacy [RxSharedPreferences] wrapper via the deprecated `rx` getter.
extension SharedPreferencesRxExtension on SharedPreferences {
  /// Returns singleton instance associated with this [SharedPreferences].
  ///
  /// Prefer [RxSharedPreferences.async] or [RxSharedPreferences.cached] for new
  /// code. Changing the underlying storage may require migrating existing data.
  @Deprecated(
    'Use RxSharedPreferences.async or RxSharedPreferences.cached for new code. '
    'Migrate existing data when changing storage.',
  )
  @legacyRxSharedPreferencesApi
  RxSharedPreferences get rx {
    final cached = _instances[this];
    if (cached != null) {
      return cached;
    }

    return _instances[this] = RxSharedPreferences.custom(
      SharedPreferencesAdapter.from(this),
      RxSharedPreferencesConfigs.logger,
      () => _instances.remove(this),
    );
  }
}
