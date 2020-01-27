import 'like_shared_prefs_test.dart' as like_shared_prefs_test;
import 'logger/default_logger_test.dart' as default_logger_test;
import 'logger/logger_adapter_test.dart' as logger_adapter_test;
import 'map_not_null_test.dart' as map_not_null_test;
import 'model/key_and_value_test.dart' as key_and_value_test;
import 'streams_test.dart' as streams_test;

void main() {
  // logger
  default_logger_test.main();
  logger_adapter_test.main();

  // model
  key_and_value_test.main();

  // rx prefs
  like_shared_prefs_test.main();
  streams_test.main();

  // map not null
  map_not_null_test.main();
}
