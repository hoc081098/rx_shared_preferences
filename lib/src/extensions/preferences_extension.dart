import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rx_shared_preferences/src/config/global_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _instances = <SharedPreferences, RxSharedPreferences>{};

/// Provide [RxSharedPreferences] via [rx] getter.
extension SharedPreferencesRxExtension on SharedPreferences {
  /// Returns singleton instance associated with this [SharedPreferences].
  RxSharedPreferences get rx {
    final instances = _instances;

    final cached = instances[this];
    if (cached != null) {
      return cached;
    }

    return instances[this] = RxSharedPreferences(
      this,
      RxSharedPreferencesConfig.logger,
      () => instances.remove(this),
    );
  }
}
