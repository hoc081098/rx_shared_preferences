import 'package:rx_storage/rx_storage.dart'
    show DefaultLogger, Logger, LoggerEvent, RxStorageError;

/// TODO
class ReloadSuccessEvent implements LoggerEvent<String, void> {
  /// TODO
  final Map<String, Object?> map;

  /// TODO
  ReloadSuccessEvent(this.map);
}

/// TODO
class ReloadFailureEvent implements LoggerEvent<String, void> {
  /// TODO
  final RxStorageError error;

  /// TODO
  ReloadFailureEvent(this.error);
}

/// TODO
abstract class RxSharedPreferencesLogger extends Logger<String, void> {}

/// Default Logger's implementation for RxSharedPreferences, simply print to the console.
class RxSharedPreferencesDefaultLogger extends DefaultLogger<String, void>
    implements RxSharedPreferencesLogger {
  /// Construct a [RxSharedPreferencesDefaultLogger].
  const RxSharedPreferencesDefaultLogger();

  /// TODO
  @override
  void log(LoggerEvent<String, void> event) {
    if (event is ReloadSuccessEvent) {
      print('ReloadSuccessEvent ${event.map}');
      return;
    }
    if (event is ReloadFailureEvent) {
      print('ReloadFailureEvent ${event.error}');
      return;
    }
    super.log(event);
  }
}
