import 'package:rx_shared_preferences/src/model/key_and_value.dart';

///
/// Log messages about operations (such as read, write, value change) and stream values
///
abstract class Logger {
  ///
  /// Called when values have changed
  ///
  void keysChanged(Iterable<KeyAndValue<dynamic>> pairs);

  ///
  /// Called when the stream emits an item
  ///
  void doOnDataStream(KeyAndValue pair);

  ///
  /// Called when the stream emits an error
  ///
  void doOnErrorStream(dynamic error, StackTrace stackTrace);

  ///
  /// Called when read value from SharedPreferences
  ///
  void readValue(Type type, String key, dynamic value);

  ///
  /// Called when write value to SharedPreferences
  ///
  void writeValue(Type type, String key, dynamic value, bool writeResult);
}
