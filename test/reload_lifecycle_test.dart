import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rx_shared_preferences/src/impl/real_rx_shared_preferences.dart';

void main() {
  group('Reload lifecycle', () {
    late _ControlledPreferences adapter;
    late _RecordingLogger logger;
    late RxSharedPreferences prefs;

    setUp(() async {
      adapter = _ControlledPreferences();
      await adapter.setString('name', 'Ada');
      logger = _RecordingLogger();
      prefs = RealRxSharedPreferences(adapter, logger);
    });

    tearDown(() => prefs.dispose());

    test(
      'reload notifies removals known only from a per-key observer',
      () async {
        final iterator = StreamIterator(prefs.getStringStream('name'));
        addTearDown(iterator.cancel);
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, 'Ada');

        await adapter.remove('name');
        expect(await prefs.reload(), isEmpty);
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, isNull);
      },
    );

    test(
      'successful writes track keys absent during the initial read',
      () async {
        final iterator = StreamIterator(prefs.getStringStream('added'));
        addTearDown(iterator.cancel);
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, isNull);
        await prefs.setString('added', 'Grace');
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, 'Grace');

        await adapter.remove('added');
        await prefs.reload();
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, isNull);
      },
    );

    test(
      'reload reconciles known keys for subsequent external changes',
      () async {
        await prefs.reload();
        final iterator = StreamIterator(prefs.getStringStream('added'));
        addTearDown(iterator.cancel);
        expect(await iterator.moveNext(), isTrue);
        await adapter.setString('added', 'Grace');
        await prefs.reload();
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, 'Grace');

        await adapter.remove('added');
        await prefs.reload();
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, isNull);
      },
    );

    test(
      'reload logs raw results and failures without publishing a failed reload',
      () async {
        final iterator = StreamIterator(prefs.getStringStream('name'));
        addTearDown(iterator.cancel);
        expect(await iterator.moveNext(), isTrue);
        await adapter.setString('name', 'Grace');
        expect(await prefs.reload(), {'name': 'Grace'});
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, 'Grace');
        await _flushEvents();

        final success = logger.events.whereType<ReloadSuccessEvent>().single;
        expect(success.keyAndValues.single.key, 'name');
        expect(success.keyAndValues.single.value, 'Grace');

        final failure = StateError('Reload failed');
        adapter.onReload = () => Future.error(failure);
        await expectLater(prefs.reload(), throwsA(same(failure)));
        await _flushEvents();
        final error = logger.events.whereType<ReloadFailureEvent>().single;
        expect(error.error.error, same(failure));
        expect(logger.events.whereType<ReloadSuccessEvent>(), hasLength(1));
      },
    );

    test('read failures complete bulk futures with an error', () async {
      final failure = StateError('Read failed');
      adapter.readFailure = failure;
      await expectLater(
        prefs.readAll((_, raw) => raw),
        throwsA(same(failure)),
      );
      await expectLater(prefs.reload(), throwsA(same(failure)));
      adapter.readFailure = null;
      expect(await prefs.reload(), {'name': 'Ada'});
    });

    test(
      'queued reloads fail on disposal and started reloads finish silently',
      () async {
        final initial = Completer<void>();
        final changes = <Map<String, Object?>>[];
        final subscription = prefs.observeAll((_, raw) => raw).listen((value) {
          changes.add(value);
          if (!initial.isCompleted) initial.complete();
        });
        addTearDown(subscription.cancel);
        await initial.future;

        final started = Completer<void>();
        final finish = Completer<Map<String, Object?>>();
        var reloadCalls = 0;
        adapter.onReload = () {
          reloadCalls++;
          started.complete();
          return finish.future;
        };
        final running = prefs.reload();
        await started.future;
        final pending = prefs.reload();
        final pendingExpectation = expectLater(pending, throwsStateError);
        await prefs.dispose();
        await pendingExpectation;
        final logCount = logger.events.length;

        finish.complete({'name': 'Grace'});
        expect(await running, {'name': 'Grace'});
        await _flushEvents();
        expect(reloadCalls, 1);
        expect(changes, [
          {'name': 'Ada'},
        ]);
        expect(logger.events, hasLength(logCount));
        expect(logger.events.whereType<ReloadSuccessEvent>(), isEmpty);
      },
    );

    test('repeated disposal shares cleanup and its result', () async {
      var cleanupCalls = 0;
      final storage = RealRxSharedPreferences(adapter, null, () {
        cleanupCalls++;
      });
      final first = storage.dispose();
      final second = storage.dispose();
      expect(identical(first, second), isTrue);
      await Future.wait([first, second]);
      expect(identical(first, storage.dispose()), isTrue);
      expect(cleanupCalls, 1);
    });

    test(
      'failed future initialization is retained until operations request it',
      () async {
        final initialization = Completer<SharedPreferencesLike>();
        final storage = RealRxSharedPreferences(initialization.future);
        addTearDown(storage.dispose);
        final failure = StateError('Initialization failed');
        initialization.completeError(failure);
        await _flushEvents();

        await expectLater(
          storage.readAll((_, raw) => raw),
          throwsA(same(failure)),
        );
        await expectLater(storage.reload(), throwsA(same(failure)));
      },
    );
  });

  test('base loggers support subclasses and handle reload events', () {
    final output = <String>[];
    final logger = _CustomDefaultLogger();
    final success = ReloadSuccessEvent([
      const KeyAndValue('name', 'Ada', String),
    ]);
    final failure = ReloadFailureEvent(
      RxStorageError(StateError('Failed'), StackTrace.current),
    );
    runZoned(
      () {
        logger.log(success);
        logger.log(failure);
        const _CustomEmptyLogger().log(success);
        const _CustomEmptyLogger().log(failure);
      },
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, line) => output.add(line),
      ),
    );
    expect(output, hasLength(3));
    expect(output[0], contains('Reload success'));
    expect(output[1], contains('Ada'));
    expect(output[2], contains('Failed'));
    expect(logger.handled, [same(success), same(failure)]);
  });
}

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

final class _RecordingLogger implements RxSharedPreferencesLogger {
  final events = <RxStorageLoggerEvent<String, void>>[];

  @override
  void log(RxStorageLoggerEvent<String, void> event) => events.add(event);
}

final class _CustomDefaultLogger extends RxSharedPreferencesDefaultLogger {
  final handled = <RxStorageLoggerEvent<String, void>>[];

  @override
  bool handleLogEvent(RxStorageLoggerEvent<String, void> event) {
    handled.add(event);
    return super.handleLogEvent(event);
  }
}

final class _CustomEmptyLogger extends RxSharedPreferencesEmptyLogger {
  const _CustomEmptyLogger();
}

final class _ControlledPreferences implements SharedPreferencesLike {
  final _storage = InMemoryStorage<String>();
  Future<Map<String, Object?>> Function()? onReload;
  Object? readFailure;

  @override
  Future<Map<String, Object?>> reload() =>
      onReload?.call() ?? _storage.readAll((_, raw) => raw);

  @override
  Future<Map<String, Object?>> readAll(
    EntryDecoder<String> decoder, [
    void options,
  ]) {
    final failure = readFailure;
    return failure == null ? _storage.readAll(decoder) : Future.error(failure);
  }

  @override
  Future<T?> read<T extends Object>(
    String key,
    Decoder<T?> decoder, [
    void options,
  ]) => _storage.read(key, decoder);

  @override
  Future<void> write<T extends Object>(
    String key,
    T? value,
    Encoder<T?> encoder, [
    void options,
  ]) => _storage.write(key, value, encoder);

  @override
  Future<bool> containsKey(String key, [void options]) =>
      _storage.containsKey(key);

  @override
  Future<void> remove(String key, [void options]) => _storage.remove(key);

  @override
  Future<void> clear([void options]) => _storage.clear();
}
