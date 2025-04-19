import 'adapter_test.dart' as adapter_test;
import 'async_streams_test.dart' as async_streams_test;
import 'legacy_streams_test.dart' as legacy_streams_test;
import 'like_shared_prefs_test.dart' as like_shared_prefs_test;
import 'with_cache_streams_test.dart' as with_cache_streams_test;

void main() {
  adapter_test.main();
  like_shared_prefs_test.main();

  legacy_streams_test.main();

  async_streams_test.main();
  with_cache_streams_test.main();
}
