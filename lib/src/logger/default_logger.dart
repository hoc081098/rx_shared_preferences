import 'package:rx_storage/rx_storage.dart';

import '../../rx_shared_preferences.dart';

/// Default [RxSharedPreferencesLogger]'s implementation, simply print to the console.
class RxSharedPreferencesDefaultLogger extends DefaultLogger<String, void>
    implements RxSharedPreferencesLogger {
  /// Construct a [RxSharedPreferencesDefaultLogger].
  const RxSharedPreferencesDefaultLogger();

  @override
  void logOther(LoggerEvent<String, void> event) {
    const rightArrow = '→';

    if (event is ReloadSuccessEvent) {
      print(' $rightArrow Reload');
      print(event.pairs.map((p) => '    $rightArrow $p').join('\n'));
      return;
    }
    if (event is ReloadFailureEvent) {
      print(' $rightArrow Reload $rightArrow ${event.error}');
      return;
    }

    super.logOther(event);
  }
}
