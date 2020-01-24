import 'package:rx_shared_preferences/src/logger/logger.dart';
import 'package:rx_shared_preferences/src/model/key_and_value.dart';

///
/// Default Logger's implementation, simply print to the console.
///
class DefaultLogger implements Logger {
  ///
  /// Construct a [DefaultLogger].
  ///
  const DefaultLogger();

  @override
  void keysChanged(Iterable<KeyAndValue> pairs) {
    print(' ↓ Key changes');
    print(pairs.map((p) => '    → $p').join('\n'));
  }

  @override
  void doOnDataStream(KeyAndValue pair) => print(' → Stream emits data: $pair');

  @override
  void doOnErrorStream(error, StackTrace stackTrace) =>
      print(' → Stream emits error: $error, $stackTrace');

  @override
  void readValue(Type type, String key, value) =>
      print(' → Read value: type $type, key $key → $value');

  @override
  void writeValue(Type type, String key, value, bool writeResult) => print(
      ' → Write value: type $type, key $key, value $value  → result $writeResult');
}
