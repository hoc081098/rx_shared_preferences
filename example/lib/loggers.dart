import 'package:rx_shared_preferences/rx_shared_preferences.dart';

// Using logger:
// 1. extends LoggerAdapter
// 2. implements Logger
// 3. DefaultLogger

/// Empty logger
class EmptyLogger extends LoggerAdapter {
  /// Override methods you want
}

/// Implements all methods
class CustomLogger implements Logger {
  @override
  void doOnDataStream(KeyAndValue<dynamic, dynamic> pair) {}

  @override
  void doOnErrorStream(dynamic error, StackTrace stackTrace) =>
      print('Error: $error');

  @override
  void keysChanged(Iterable<KeyAndValue<dynamic, dynamic>> pairs) {}

  @override
  void readValue(Type type, Object key, dynamic value) {}

  @override
  void writeValue(Type type, Object key, dynamic value, bool writeResult) {}
}

/// Or using default logger
const defaultLogger = DefaultLogger();
