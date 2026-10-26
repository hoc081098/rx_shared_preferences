import 'package:rx_storage/rx_storage.dart'
    show KeyAndValue, RxStorageError, RxStorageLogger, RxStorageLoggerEvent;

/// Log messages about operations (such as read, write, value change) and stream events.
/// Must handle [ReloadSuccessEvent] and [ReloadFailureEvent].
///
/// Implement this contract to provide a custom logger.
abstract interface class RxSharedPreferencesLogger
    implements RxStorageLogger<String, void> {}

/// Reload successfully.
final class ReloadSuccessEvent implements RxStorageLoggerEvent<String, void> {
  /// A list containing all values after reload.
  final List<KeyAndValue<String, Object?>> keyAndValues;

  /// Construct a [ReloadSuccessEvent].
  ReloadSuccessEvent(this.keyAndValues);
}

/// Reload failed.
final class ReloadFailureEvent implements RxStorageLoggerEvent<String, void> {
  /// The error occurred when reloading.
  final RxStorageError error;

  /// Construct a [ReloadFailureEvent].
  ReloadFailureEvent(this.error);
}
