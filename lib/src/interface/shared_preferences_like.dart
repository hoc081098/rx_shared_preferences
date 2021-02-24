import 'package:flutter/services.dart' show MethodChannel;
import 'package:rx_storage/rx_storage.dart';

/// Wraps NSUserDefaults (on iOS) and SharedPreferences (on Android), providing
/// a persistent store for simple data.
///
/// Data is persisted to disk asynchronously.
abstract class SharedPreferencesLike extends Storage<String, void> {
  /// Error code when an error occurs when calling a method from [MethodChannel].
  static const errorCode = 'shared-preferences-error';

  /// Fetches the latest values from the host platform.
  ///
  /// Use this method to observe modifications that were made in native code
  /// (without using the plugin) while the app is running.
  Future<Map<String, Object?>> reload();
}
