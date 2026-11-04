import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

const _testData = <String, String>{'allowed': 'initial', 'blocked': 'other'};

void main() {
  late _RecordingPreferences platform;

  setUp(() {
    platform = _RecordingPreferences();
    SharedPreferencesAsyncPlatform.instance = platform;

    final originalLogger = RxSharedPreferencesConfigs.logger;
    RxSharedPreferencesConfigs.logger = null;
    addTearDown(() => RxSharedPreferencesConfigs.logger = originalLogger);
  });

  test(
    'async singleton keeps its first storage options until disposal',
    () async {
      const firstOptions = _TestStorageOptions('first');
      const nextOptions = _TestStorageOptions('next');
      final prefs = RxSharedPreferences.getAsyncInstance(options: firstOptions);
      addTearDown(prefs.dispose);
      expect(await prefs.getString('allowed'), 'initial');
      await prefs.setString('allowed', 'updated');

      final reused = RxSharedPreferences.getAsyncInstance(options: nextOptions);
      expect(identical(reused, prefs), isTrue);
      expect(await reused.getString('allowed'), 'updated');
      expect(platform.receivedOptions, everyElement(same(firstOptions)));

      await prefs.dispose();
      platform.receivedOptions.clear();
      final replacement = RxSharedPreferences.getAsyncInstance(
        options: nextOptions,
      );
      addTearDown(replacement.dispose);
      expect(identical(replacement, prefs), isFalse);
      expect(await replacement.getString('allowed'), 'updated');
      await replacement.setString('allowed', 'replacement');
      expect(platform.receivedOptions, everyElement(same(nextOptions)));
    },
  );

  test('cached forwards initialization, logging and disposal', () async {
    final initialization = Completer<SharedPreferencesWithCache>();
    final logger = _RecordingLogger();
    var disposalCalls = 0;
    final prefs = RxSharedPreferences.cached(
      initialization.future,
      logger,
      () => disposalCalls++,
    );
    addTearDown(prefs.dispose);
    final read = prefs.getString('allowed');
    final raw = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    initialization.complete(raw);

    expect(await read, 'initial');
    await prefs.setString('allowed', 'updated');
    expect(raw.getString('allowed'), 'updated');
    await prefs.reload();
    expect(logger.events.whereType<ReloadSuccessEvent>(), hasLength(1));
    await prefs.dispose();
    await prefs.dispose();
    expect(disposalCalls, 1);
  });

  test(
    'cached singleton keeps its first options, cache and logger until disposal',
    () async {
      const cacheOptions = SharedPreferencesWithCacheOptions(
        allowList: {'allowed'},
      );

      const firstStorageOptions = _TestStorageOptions('first');
      const nextStorageOptions = _TestStorageOptions('next');
      final firstCache = <String, Object?>{'stale': 'cached only'};
      final nextCache = <String, Object?>{'ignored': 'unchanged'};

      final firstLogger = _RecordingLogger();
      RxSharedPreferencesConfigs.logger = firstLogger;
      final prefs = RxSharedPreferences.getCachedInstance(
        sharedPreferencesOptions: firstStorageOptions,
        cacheOptions: cacheOptions,
        cache: firstCache,
      );
      addTearDown(prefs.dispose);

      final nextLogger = _RecordingLogger();
      RxSharedPreferencesConfigs.logger = nextLogger;
      final reused = RxSharedPreferences.getCachedInstance(
        sharedPreferencesOptions: nextStorageOptions,
        cacheOptions: const SharedPreferencesWithCacheOptions(),
        cache: nextCache,
      );

      expect(identical(prefs, reused), isTrue);
      expect(await prefs.getKeys(), {'allowed'});
      expect(firstCache, {'allowed': 'initial'});
      expect(nextCache, {'ignored': 'unchanged'});
      await expectLater(prefs.getString('blocked'), throwsArgumentError);

      await prefs.setString('allowed', 'updated');
      expect(firstCache, {'allowed': 'updated'});

      await prefs.reload();
      expect(platform.receivedOptions, everyElement(same(firstStorageOptions)));
      expect(firstLogger.events.whereType<ReloadSuccessEvent>(), hasLength(1));
      expect(nextLogger.events, isEmpty);

      await prefs.dispose();
      platform.receivedOptions.clear();
      final replacement = RxSharedPreferences.getCachedInstance(
        sharedPreferencesOptions: nextStorageOptions,
        cacheOptions: const SharedPreferencesWithCacheOptions(),
        cache: nextCache,
      );
      addTearDown(replacement.dispose);

      expect(identical(replacement, prefs), isFalse);
      expect(await replacement.getKeys(), {'allowed', 'blocked'});
      expect(nextCache, {'allowed': 'updated', 'blocked': 'other'});
      await replacement.reload();
      expect(platform.receivedOptions, everyElement(same(nextStorageOptions)));
      expect(nextLogger.events.whereType<ReloadSuccessEvent>(), hasLength(1));
    },
  );
}

final class _TestStorageOptions extends SharedPreferencesOptions {
  const _TestStorageOptions(this.name);

  final String name;
}

final class _RecordingPreferences extends InMemorySharedPreferencesAsync {
  _RecordingPreferences() : super.withData(_testData);

  final receivedOptions = <SharedPreferencesOptions>[];

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) {
    receivedOptions.add(options);
    return super.getPreferences(parameters, options);
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    receivedOptions.add(options);
    return super.setString(key, value, options);
  }
}

final class _RecordingLogger implements RxSharedPreferencesLogger {
  final events = <RxStorageLoggerEvent<String, void>>[];

  @override
  void log(RxStorageLoggerEvent<String, void> event) => events.add(event);
}
