import '../logger.dart';

/// Global configs for default singleton or extension.
class RxSharedPreferencesConfigs {
  /// Config for logger.
  static RxSharedPreferencesLogger? logger =
      const RxSharedPreferencesDefaultLogger();
}
