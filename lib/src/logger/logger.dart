import 'package:rx_storage/rx_storage.dart'
    show KeyAndValue, RxStorageError, RxStorageLogger, RxStorageLoggerEvent;

/// Log messages about operations (such as read, write, value change) and stream events.
/// Must handle [ReloadSuccessEvent] and [ReloadFailureEvent].
abstract class RxSharedPreferencesLogger extends RxStorageLogger<String, void> {
}

/// Reload successfully.
class ReloadSuccessEvent implements RxStorageLoggerEvent<String, void> {
  /// A list containing all values after reload.
  final List<KeyAndValue<String, Object?>> keyAndValues;

  /// Construct a [ReloadSuccessEvent].
  ReloadSuccessEvent(this.keyAndValues);
}

/// Reload failed.
class ReloadFailureEvent implements RxStorageLoggerEvent<String, void> {
  /// The error occurred when reloading.
  final RxStorageError error;

  /// Construct a [ReloadFailureEvent].
  ReloadFailureEvent(this.error);
}
