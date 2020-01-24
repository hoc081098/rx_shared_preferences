import 'like_shared_prefs_test.dart' as like_shared_prefs_test;
import 'streams_test.dart' as streams_test;
import 'logger/default_logger_test.dart' as default_logger_test;
import 'model/key_and_value_test.dart' as key_and_value_test;

void main() {
  default_logger_test.main();
  key_and_value_test.main();
  like_shared_prefs_test.main();
  streams_test.main();
}
