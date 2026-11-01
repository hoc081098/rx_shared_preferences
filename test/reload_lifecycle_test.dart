import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rx_shared_preferences/src/impl/real_rx_shared_preferences.dart';

import 'stream_expectations.dart';

enum _ReloadPhase { keyScan, platformReload }

void main() {
  group('reload', () {
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

    group('async gaps', () {
      for (final phase in _ReloadPhase.values) {
        group(phase.name, () {
          test('includes keys learned by a pending read', () async {
            final readStarted = Completer<void>();
            final finishRead = Completer<Object?>();
            adapter.onRead = (key) {
              expect(key, 'name');
              readStarted.complete();
              return finishRead.future;
            };
            addTearDown(() {
              if (!finishRead.isCompleted) finishRead.complete(null);
            });
            final output = expectStreamEvents(prefs.getStringStream('name'), [
              'Ada',
              null,
            ]);
            await readStarted.future;
            await adapter.remove('name');

            final gate = _blockReload(adapter, phase);
            addTearDown(gate.resume);
            final reload = prefs.reload();
            await gate.started;
            finishRead.complete('Ada');
            await output.firstEvent;
            gate.resume();
            expect(await reload, isEmpty);
            await prefs.reload();
            await prefs.dispose();
            await output.done;
          });

          test('does not repeat a completed local removal', () async {
            final output = expectStreamEvents(prefs.getStringStream('name'), [
              'Ada',
              null,
            ]);
            await output.firstEvent;
            final gate = _blockReload(adapter, phase);
            addTearDown(gate.resume);
            final reload = prefs.reload();
            await gate.started;
            await prefs.remove('name');
            gate.resume();
            expect(await reload, isEmpty);
            await prefs.dispose();
            await output.done;
          });
        });
      }
    });

    group('notifications', () {
      test('remembers keys observed by per-key streams', () async {
        final output = expectStreamEvents(prefs.getStringStream('name'), [
          'Ada',
          null,
        ]);
        await output.firstEvent;
        await adapter.remove('name');
        expect(await prefs.reload(), isEmpty);
        await prefs.dispose();
        await output.done;
      });

      test('tracks successful writes after an initially missing key', () async {
        final output = expectStreamEvents(prefs.getStringStream('added'), [
          null,
          'Grace',
          null,
        ]);
        await output.firstEvent;
        await prefs.setString('added', 'Grace');
        await adapter.remove('added');
        await prefs.reload();
        await prefs.dispose();
        await output.done;
      });

      test('retains keys after a failed encoded removal', () async {
        final output = expectStreamEvents(prefs.getStringStream('name'), [
          'Ada',
          null,
        ]);
        await output.firstEvent;
        final failure = StateError('Remove failed');
        adapter.writeFailure = failure;
        await expectLater(
          prefs.setString('name', null),
          throwsA(same(failure)),
        );
        adapter.writeFailure = null;
        await adapter.remove('name');
        expect(await prefs.reload(), isEmpty);
        await prefs.dispose();
        await output.done;
      });

      test('reconciles keys across successive external changes', () async {
        await prefs.reload();
        final output = expectStreamEvents(prefs.getStringStream('added'), [
          null,
          'Grace',
          null,
        ]);
        await output.firstEvent;
        await adapter.setString('added', 'Grace');
        await prefs.reload();
        await adapter.remove('added');
        await prefs.reload();
        await prefs.dispose();
        await output.done;
      });
    });

    group('failures and logging', () {
      test('logs raw results, preserves failures and supports retry', () async {
        final output = expectStreamEvents(prefs.getStringStream('name'), [
          'Ada',
          'Grace',
          null,
        ]);
        await output.firstEvent;
        await adapter.setString('name', 'Grace');
        expect(await prefs.reload(), {'name': 'Grace'});
        final success = logger.events.whereType<ReloadSuccessEvent>().single;
        expect(success.keyAndValues.single.key, 'name');
        expect(success.keyAndValues.single.value, 'Grace');

        final failure = StateError('Reload failed');
        await adapter.remove('name');
        adapter.onReload = () => Future.error(failure);
        await expectLater(prefs.reload(), throwsA(same(failure)));
        final error = logger.events.whereType<ReloadFailureEvent>().single;
        expect(error.error.error, same(failure));
        expect(logger.events.whereType<ReloadSuccessEvent>(), hasLength(1));

        adapter.onReload = null;
        expect(await prefs.reload(), isEmpty);
        await prefs.dispose();
        await output.done;
      });

      test('propagates and logs key-scan failures', () async {
        final failure = StateError('Read failed');
        adapter.readFailure = failure;
        await expectLater(
          prefs.readAll((_, raw) => raw),
          throwsA(same(failure)),
        );
        await expectLater(prefs.reload(), throwsA(same(failure)));
        expect(
          logger.events.whereType<ReloadFailureEvent>().single.error.error,
          same(failure),
        );
        adapter.readFailure = null;
        expect(await prefs.reload(), {'name': 'Ada'});
      });
    });

    group('queue and disposal', () {
      test('shares a queue with clear', () async {
        final started = Completer<void>();
        final finish = Completer<Map<String, Object?>>();
        adapter.onReload = () {
          started.complete();
          return finish.future;
        };
        final completed = <String>[];
        final reload = prefs.reload().then((_) => completed.add('reload'));
        await started.future;
        final clear = prefs.clear().then((_) => completed.add('clear'));
        try {
          await _flushEvents();
          expect(await adapter.getString('name'), 'Ada');
          expect(completed, isEmpty);
        } finally {
          finish.complete({'name': 'Ada'});
          await Future.wait([reload, clear]);
        }
        expect(completed, ['reload', 'clear']);
        expect(await adapter.getKeys(), isEmpty);
      });

      test(
        'rejects queued reloads and lets a running reload finish silently',
        () async {
          final output = expectStreamEvents(prefs.observeAll((_, raw) => raw), [
            {'name': 'Ada'},
          ]);
          await output.firstEvent;
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
          final pending = expectLater(prefs.reload(), throwsStateError);
          await prefs.dispose();
          await pending;
          await output.done;
          final logCount = logger.events.length;

          finish.complete({'name': 'Grace'});
          expect(await running, {'name': 'Grace'});
          await _flushEvents();
          expect(reloadCalls, 1);
          expect(logger.events, hasLength(logCount));
          expect(logger.events.whereType<ReloadSuccessEvent>(), isEmpty);
        },
      );

      test('shares repeated disposal and invokes cleanup once', () async {
        var cleanupCalls = 0;
        final storage = RealRxSharedPreferences(
          adapter,
          null,
          () => cleanupCalls++,
        );
        final first = storage.dispose();
        final second = storage.dispose();
        expect(identical(first, second), isTrue);
        await Future.wait([first, second]);
        expect(identical(first, storage.dispose()), isTrue);
        expect(cleanupCalls, 1);
      });

      test('retains initialization errors for subsequent operations', () async {
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
      });
    });
  });

  group('loggers', () {
    final success = ReloadSuccessEvent([
      const KeyAndValue('name', 'Ada', String),
    ]);
    final failure = ReloadFailureEvent(
      RxStorageError(StateError('Failed'), StackTrace.current),
    );

    test('default logger subclasses handle reload events', () {
      final logger = _CustomDefaultLogger();
      final output = _capturePrints(() {
        logger.log(success);
        logger.log(failure);
      });
      expect(output, hasLength(3));
      expect(output[0], contains('Reload success'));
      expect(output[1], contains('Ada'));
      expect(output[2], contains('Failed'));
      expect(logger.handled, [same(success), same(failure)]);
    });

    test('empty logger ignores reload events', () {
      final output = _capturePrints(() {
        const RxSharedPreferencesEmptyLogger().log(success);
        const RxSharedPreferencesEmptyLogger().log(failure);
      });
      expect(output, isEmpty);
    });
  });
}

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

({Future<void> started, void Function() resume}) _blockReload(
  _ControlledPreferences adapter,
  _ReloadPhase phase,
) {
  final started = Completer<void>();
  final release = Completer<void>();
  Future<void> wait() {
    started.complete();
    return release.future;
  }

  if (phase == _ReloadPhase.keyScan) {
    adapter.beforeReadAll = wait;
  } else {
    adapter.onReload = () async {
      await wait();
      return adapter.readAll((_, raw) => raw);
    };
  }
  return (
    started: started.future,
    resume: () {
      adapter.beforeReadAll = null;
      adapter.onReload = null;
      if (!release.isCompleted) release.complete();
    },
  );
}

List<String> _capturePrints(void Function() action) {
  final output = <String>[];
  runZoned(
    action,
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => output.add(line),
    ),
  );
  return output;
}

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
