// ignore_for_file: avoid_print

import 'package:rx_storage/rx_storage.dart';

import 'logger.dart';

/// Default [RxSharedPreferencesLogger]'s implementation, simply print to the console.
class RxSharedPreferencesDefaultLogger
    extends RxStorageDefaultLogger<String, void>
    implements RxSharedPreferencesLogger {
  /// Default logger tag.
  static const defaultTag = '⚡ RxSharedPreferences';

  /// Construct a [RxSharedPreferencesDefaultLogger].
  const RxSharedPreferencesDefaultLogger(
      {String tag = defaultTag, bool trimValueOutput = false})
      : super(tag: tag, trimValueOutput: trimValueOutput);

  @override
  bool handleLogEvent(RxStorageLoggerEvent<String, void> event) {
    const rightArrow = RxStorageDefaultLogger.rightArrow;
    const leftArrow = RxStorageDefaultLogger.leftArrow;
    const downArrow = RxStorageDefaultLogger.downArrow;

    if (event is ReloadSuccessEvent) {
      print('$tag $downArrow Reload success');
      print(event.keyAndValues
          .map((p) => '    $rightArrow ${keyAndValueToString(p)}')
          .join('\n'));
      return true;
    }

    if (event is ReloadFailureEvent) {
      print('$tag $leftArrow Reload $rightArrow ${event.error}');
      return true;
    }

    return false;
  }
}
