import 'package:shared_preferences/shared_preferences.dart';

import '../config/global_config.dart';
import '../interface/rx_shared_preferences.dart';

final _instances = <SharedPreferences, RxSharedPreferences>{};

/// Provide [RxSharedPreferences] via [rx] getter.
extension SharedPreferencesRxExtension on SharedPreferences {
  /// Returns singleton instance associated with this [SharedPreferences].
  RxSharedPreferences get rx {
    final cached = _instances[this];
    if (cached != null) {
      return cached;
    }

    return _instances[this] = RxSharedPreferences(
      this,
      RxSharedPreferencesConfigs.logger,
      () => _instances.remove(this),
    );
  }
}
