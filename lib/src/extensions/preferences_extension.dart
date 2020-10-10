import 'dart:async';

import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provide [RxSharedPreferences] via [rx] getter.
extension SharedPreferencesRxExtension on FutureOr<SharedPreferences> {
  /// Returns default singleton instance.
  RxSharedPreferences get rx => RxSharedPreferences.getInstance();
}
