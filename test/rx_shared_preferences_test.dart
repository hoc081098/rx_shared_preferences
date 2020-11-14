import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

import 'adapter_test.dart' as adapter_test;
import 'like_shared_prefs_test.dart' as like_shared_prefs_test;
import 'streams_test.dart' as streams_test;

void main() {
  test('RxSharedPreferences.asserts', () {
    expect(
      () => RxSharedPreferences(null),
      throwsAssertionError,
    );
  });

  adapter_test.main();
  like_shared_prefs_test.main();
  streams_test.main();
}
