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

    for (final phase in ['key scan', 'delegate reload']) {
      test('reload includes keys learned by a read during $phase', () async {
        final readStarted = Completer<void>();
        final finishRead = Completer<Object?>();
        adapter.onRead = (key) {
          expect(key, 'name');
          readStarted.complete();
          return finishRead.future;
        };

        final initial = Completer<void>();
        final events = <String?>[];
        final subscription = prefs.getStringStream('name').listen((value) {
          events.add(value);
          if (!initial.isCompleted) initial.complete();
        });
        addTearDown(subscription.cancel);
        await readStarted.future;
        await adapter.remove('name');

        final phaseStarted = Completer<void>();
        final finishPhase = Completer<void>();
        if (phase == 'key scan') {
          adapter.beforeReadAll = () {
            phaseStarted.complete();
            return finishPhase.future;
          };
        } else {
          adapter.onReload = () async {
            phaseStarted.complete();
            await finishPhase.future;
            return <String, Object?>{};
          };
        }

        final reload = prefs.reload();
        await phaseStarted.future;
        // The per-key read captured this value before the external removal,
        // but only delivers it after reload has started scanning current keys.
        finishRead.complete('Ada');
        await initial.future;
        finishPhase.complete();
        expect(await reload, isEmpty);
        await _flushEvents();

        expect(events, ['Ada', null]);

        adapter.beforeReadAll = null;
        adapter.onReload = null;
        await prefs.reload();
        await _flushEvents();
        expect(events, ['Ada', null]);
      });
    }

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

    test('failed encoded removals retain keys for external reloads', () async {
      final initial = Completer<void>();
      final events = <String?>[];
      final subscription = prefs.getStringStream('name').listen((value) {
        events.add(value);
        if (!initial.isCompleted) initial.complete();
      });
      addTearDown(subscription.cancel);
      await initial.future;

      final failure = StateError('Remove failed');
      adapter.writeFailure = failure;
      await expectLater(prefs.setString('name', null), throwsA(same(failure)));
      await _flushEvents();
      expect(events, ['Ada']);

      adapter.writeFailure = null;
      await adapter.remove('name');
      expect(await prefs.reload(), isEmpty);
      await _flushEvents();
      expect(events, ['Ada', null]);
    });

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
        await adapter.remove('name');
        adapter.onReload = () => Future.error(failure);
        await expectLater(prefs.reload(), throwsA(same(failure)));
        await _flushEvents();
        final error = logger.events.whereType<ReloadFailureEvent>().single;
        expect(error.error.error, same(failure));
        expect(logger.events.whereType<ReloadSuccessEvent>(), hasLength(1));

        adapter.onReload = null;
        expect(await prefs.reload(), isEmpty);
        expect(await iterator.moveNext(), isTrue);
        expect(iterator.current, isNull);
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
      await _flushEvents();
      expect(
        logger.events.whereType<ReloadFailureEvent>().single.error.error,
        same(failure),
      );
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

  test('default logger supports subclasses and empty logger stays silent', () {
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
        const RxSharedPreferencesEmptyLogger().log(success);
        const RxSharedPreferencesEmptyLogger().log(failure);
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

final class _ControlledPreferences implements SharedPreferencesLike {
  final _storage = InMemoryStorage<String>();
  Future<Map<String, Object?>> Function()? onReload;
  Future<void> Function()? beforeReadAll;
  Future<Object?> Function(String key)? onRead;
  Object? readFailure;
  Object? writeFailure;

  @override
  Future<Map<String, Object?>> reload() =>
      onReload?.call() ?? _storage.readAll((_, raw) => raw);

  @override
  Future<Map<String, Object?>> readAll(
    EntryDecoder<String> decoder, [
    void options,
  ]) async {
    final failure = readFailure;
    if (failure != null) throw failure;
    await beforeReadAll?.call();
    return _storage.readAll(decoder);
  }

  @override
  Future<T?> read<T extends Object>(
    String key,
    Decoder<T?> decoder, [
    void options,
  ]) {
    final read = onRead;
    return read == null
        ? _storage.read(key, decoder)
        : Future.sync(() => read(key)).then(decoder);
  }

  @override
  Future<void> write<T extends Object>(
    String key,
    T? value,
    Encoder<T?> encoder, [
    void options,
  ]) {
    final failure = writeFailure;
    if (failure != null) {
      return Future.sync(() => encoder(value)).then((_) => throw failure);
    }
    return _storage.write(key, value, encoder);
  }

  @override
  Future<bool> containsKey(String key, [void options]) =>
      _storage.containsKey(key);

  @override
  Future<void> remove(String key, [void options]) => _storage.remove(key);

  @override
  Future<void> clear([void options]) => _storage.clear();
}
