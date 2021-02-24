import '../logger/default_logger.dart';
import '../logger/logger.dart';

/// Global configs for default singleton or extension.
class RxSharedPreferencesConfigs {
  /// Config for logger.
  /// Default value is a [RxSharedPreferencesDefaultLogger].
  /// Can be set to `null` to disable logging.
  static RxSharedPreferencesLogger? logger =
      const RxSharedPreferencesDefaultLogger();
}
