import 'package:rx_shared_preferences/src/model/key_and_value.dart';

abstract class Logger {
  void keysChanged(Iterable<KeyAndValue<dynamic>> pairs);

  void doOnDataStream(KeyAndValue pair);

  void doOnErrorStream(dynamic error, StackTrace stackTrace);

  void readValue(Type type, String key, dynamic value);

  void writeValue(Type type, String key, dynamic value, bool writeResult);
}
