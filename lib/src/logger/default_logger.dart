import 'package:rx_storage/rx_storage.dart';

import '../../rx_shared_preferences.dart';

/// Default [RxSharedPreferencesLogger]'s implementation, simply print to the console.
class RxSharedPreferencesDefaultLogger extends DefaultLogger<String, void>
    implements RxSharedPreferencesLogger {
  /// Default logger tag.
  static const defaultTag = '⚡ RxSharedPreferences';

  /// Construct a [RxSharedPreferencesDefaultLogger].
  const RxSharedPreferencesDefaultLogger(
      {String tag = defaultTag, bool trimValueOutput = false})
      : super(tag: tag, trimValueOutput: trimValueOutput);

  @override
  void logOther(LoggerEvent<String, void> event) {
    const rightArrow = DefaultLogger.rightArrow;
    const downArrow = DefaultLogger.downArrow;

    if (event is ReloadSuccessEvent) {
      print('$tag $downArrow Reload success');
      print(event.keyAndValues
          .map((p) => '    $rightArrow ${keyAndValueToString(p)}')
          .join('\n'));
      return;
    }

    if (event is ReloadFailureEvent) {
      print('$tag $rightArrow Reload $rightArrow ${event.error}');
      return;
    }

    super.logOther(event);
  }
}
