import 'package:flutter/services.dart' show MethodChannel;
import 'package:rx_storage/rx_storage.dart';

/// Wraps NSUserDefaults (on iOS) and SharedPreferences (on Android), providing
/// a persistent store for simple data.
///
/// Data is persisted to disk asynchronously.
/// Encoded nulls remove their keys.
///
/// The bundled adapters capture a shallow entry snapshot for [Storage.readAll]
/// before invoking its decoders. Decoders may run concurrently and return
/// synchronous or asynchronous values. Null decoding results retain their keys.
///
/// Implement this contract to provide a custom adapter.
abstract interface class SharedPreferencesLike
    implements Storage<String, void> {
  /// Error code when an error occurs when calling a method from [MethodChannel].
  static const errorCode = 'shared-preferences-error';

  /// Fetches the latest values from the host platform.
  ///
  /// Use this method to observe modifications that were made in native code
  /// (without using the plugin) while the app is running.
  Future<Map<String, Object?>> reload();
}
