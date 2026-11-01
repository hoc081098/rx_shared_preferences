import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rx_shared_preferences/src/impl/async/shared_preferences_async_adapter.dart';
import 'package:rx_shared_preferences/src/impl/async/shared_preferences_with_cache_adapter.dart';
import 'package:rx_shared_preferences/src/impl/legacy/shared_preferences_adapter.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'stream_expectations.dart';

enum _AdapterKind { legacy, async, withCache }

const _initialValues = <String, Object>{
  'count': 1,
  'name': 'Ada',
  'tags': <String>['one'],
};

void main() {
  for (final kind in _AdapterKind.values) {
    group('${kind.name} adapter', () {
      late _PreferencesFixture fixture;
      late SharedPreferencesLike adapter;
      late RxSharedPreferences prefs;

      setUp(() async {
        fixture = await _PreferencesFixture.create(kind);
        adapter = fixture.adapter;
        prefs = fixture.prefs;
      });
      tearDown(() => prefs.dispose());

      group('readAll', () {
        test('reads raw entries and keys', () async {
          expect(await adapter.readAll((_, raw) => raw), _initialValues);
          expect(await prefs.readAll((_, raw) => raw), _initialValues);
          expect(await prefs.getKeys(), _initialValues.keys.toSet());
        });

        test('supports key-specific sync, async and null results', () async {
          final keys = <String>[];
          final result = await adapter.readAll((key, raw) {
            keys.add(key);
            return switch (key) {
              'count' => Future<String>.value('$key=$raw'),
              'name' => (raw as String).length,
              'tags' => null,
              _ => throw StateError('Unexpected key: $key'),
            };
          });
          expect(keys, unorderedEquals(_initialValues.keys));
          expect(result, {'count': 'count=1', 'name': 3, 'tags': null});
          expect(await adapter.readAll((_, raw) => raw), _initialValues);
        });

        test('does not decode empty storage', () async {
          await adapter.clear();
          expect(
            await adapter.readAll((_, _) => fail('No entries to decode')),
            isEmpty,
          );
        });

        test('decodes a snapshot when the decoder mutates storage', () async {
          final mutations = <Future<void>>[];
          final result = await adapter.readAll((key, raw) {
            if (mutations.isEmpty) {
              mutations.addAll([
                adapter.setString('name', 'Grace'),
                adapter.remove('tags'),
                adapter.setInt('added', 2),
              ]);
            }
            return raw;
          });
          await Future.wait(mutations);
          expect(result, _initialValues);
          expect(await adapter.readAll((_, raw) => raw), {
            'count': 1,
            'name': 'Grace',
            'added': 2,
          });
        });

        test('copies maps and cached string lists', () async {
          final result = await adapter.readAll((_, raw) => raw);
          if (kind != _AdapterKind.async) {
            (result['tags'] as List<String>).add('changed');
          }
          result['count'] = 99;
          expect(await adapter.getStringList('tags'), ['one']);
          expect(await adapter.getInt('count'), 1);
        });

        test('retains decoded nulls and omits removed keys', () async {
          final decoded = await adapter.readAll((_, _) => null);
          expect(decoded.keys, unorderedEquals(_initialValues.keys));
          expect(decoded.values, everyElement(isNull));

          await adapter.setString('name', null);
          expect(
            (await adapter.readAll((_, raw) => raw)).containsKey('name'),
            isFalse,
          );
          expect(await adapter.containsKey('name'), isFalse);
        });

        for (final asynchronous in [false, true]) {
          test(
            'reports ${asynchronous ? 'async' : 'sync'} errors immediately',
            () async {
              final pending = Completer<Object?>();
              final failure = StateError('Cannot decode name');
              final stackTrace = StackTrace.current;
              Object? observedError;
              StackTrace? observedStackTrace;
              final result = adapter.readAll((key, raw) {
                if (key == 'count') return pending.future;
                if (key == 'name') {
                  if (asynchronous) {
                    return Future<Object?>.error(failure, stackTrace);
                  }
                  Error.throwWithStackTrace(failure, stackTrace);
                }
                return raw;
              });
              final handled = result.then<void>(
                (_) => fail('A failed bulk read must not return a map'),
                onError: (Object error, StackTrace trace) {
                  observedError = error;
                  observedStackTrace = trace;
                },
              );
              try {
                await _flushEvents();
                expect(observedError, same(failure));
                expect(observedStackTrace.toString(), stackTrace.toString());
                expect(pending.isCompleted, isFalse);
              } finally {
                pending.completeError(StateError('Late decoder failure'));
                await handled;
                await _flushEvents();
              }
              expect(await adapter.readAll((_, raw) => raw), _initialValues);
            },
          );
        }
      });

      group('observeAll', () {
        test('decodes initial data and each mutation', () async {
          await prefs.clear();
          final iterator = StreamIterator(
            prefs.observeAll((key, raw) => '$key=$raw'),
          );
          addTearDown(iterator.cancel);

          // Advance each read before the next mutation changes its snapshot.
          await _expectNext(iterator, <String, Object?>{});
          await prefs.setInt('count', 1);
          await _expectNext(iterator, {'count': 'count=1'});
          await prefs.updateInt('count', (value) async => value! + 1);
          await _expectNext(iterator, {'count': 'count=2'});
          await prefs.setString('name', 'Ada');
          await _expectNext(iterator, {'count': 'count=2', 'name': 'name=Ada'});
          await prefs.remove('count');
          await _expectNext(iterator, {'name': 'name=Ada'});
          await prefs.clear();
          await _expectNext(iterator, <String, Object?>{});
        });

        test('retains decoded nulls until removal', () async {
          final iterator = StreamIterator(prefs.observeAll((_, _) => null));
          addTearDown(iterator.cancel);
          await _expectNext(iterator, {
            'count': null,
            'name': null,
            'tags': null,
          });
          await prefs.remove('name');
          await _expectNext(iterator, {'count': null, 'tags': null});
        });

        for (final asynchronous in [false, true]) {
          test(
            'recovers after ${asynchronous ? 'async' : 'sync'} decoder errors',
            () async {
              final failure = StateError('Cannot decode count');
              final decodingFailed = Completer<void>();
              final output = expectStreamEvents(
                prefs
                    .observeAll((key, raw) {
                      if (key == 'count' && raw == 2) {
                        decodingFailed.complete();
                        if (asynchronous) return Future<Object?>.error(failure);
                        throw failure;
                      }
                      return raw;
                    })
                    .map((values) => values['count']),
                [1, emitsError(same(failure)), 3],
              );
              await output.firstEvent;
              await prefs.setInt('count', 2);
              await decodingFailed.future;
              await prefs.setInt('count', 3);
              await prefs.dispose();
              await output.done;
            },
          );
        }

        test('preserves emission order during async decoding', () async {
          final decodingStarted = Completer<void>();
          final finishDecoding = Completer<Object?>();
          final decodedCounts = <Object?>[];
          final stream = prefs.observeAll((key, raw) {
            if (key == 'count') {
              decodedCounts.add(raw);
              if (!decodingStarted.isCompleted) {
                decodingStarted.complete();
                return finishDecoding.future;
              }
            }
            return raw;
          });
          final expectation = expectLater(
            stream.map((values) => values['count']),
            emitsInOrder([1, 3, 3]),
          );
          await decodingStarted.future;
          await prefs.setInt('count', 2);
          await prefs.setInt('count', 3);
          expect(decodedCounts, [1]);
          finishDecoding.complete(1);
          await expectation;
          expect(decodedCounts, [1, 3, 3]);
        });

        test('is single-subscription', () async {
          final stream = prefs.observeAll((_, raw) => raw);
          expect(stream.isBroadcast, isFalse);
          final subscription = stream.listen(null);
          expect(() => stream.listen(null), throwsStateError);
          await subscription.cancel();
        });
      });

      group('reload', () {
        test(
          'notifies key, keys and bulk streams of external changes',
          () async {
            final count = expectStreamEvents(prefs.getIntStream('count'), [
              1,
              2,
            ]);
            final name = expectStreamEvents(prefs.getStringStream('name'), [
              'Ada',
              null,
            ]);
            final added = expectStreamEvents(prefs.getStringStream('added'), [
              null,
              'Grace',
            ]);
            final keys = expectStreamEvents(prefs.getKeysStream(), [
              {'count', 'name', 'tags'},
              {'count', 'added'},
            ]);
            final decoded = expectStreamEvents(
              prefs.observeAll((key, raw) => '$key=$raw'),
              [
                {'count': 'count=1', 'name': 'name=Ada', 'tags': 'tags=[one]'},
                {'count': 'count=2', 'added': 'added=Grace'},
              ],
            );
            await Future.wait([
              count.firstEvent,
              name.firstEvent,
              added.firstEvent,
              keys.firstEvent,
              decoded.firstEvent,
            ]);
            await fixture.replaceExternal({'count': 2, 'added': 'Grace'});
            expect(await prefs.reload(), {'count': 2, 'added': 'Grace'});
            await prefs.dispose();
            await Future.wait([
              count.done,
              name.done,
              added.done,
              keys.done,
              decoded.done,
            ]);
          },
        );

        for (final asynchronous in [false, true]) {
          group('${asynchronous ? 'async' : 'sync'} codecs', () {
            test('encoder errors preserve existing and missing keys', () async {
              await prefs.clear();
              await prefs.setString('name', 'Ada');
              final names = expectStreamEvents(prefs.getStringStream('name'), [
                'Ada',
                null,
              ]);
              final added = expectStreamEvents(prefs.getStringStream('added'), [
                null,
              ]);
              await Future.wait([names.firstEvent, added.firstEvent]);

              final failure = StateError('Cannot encode');
              for (final key in ['name', 'added']) {
                await expectLater(
                  prefs.write<String>(key, 'Grace', (_) {
                    if (asynchronous) return Future<Object?>.error(failure);
                    throw failure;
                  }),
                  throwsA(same(failure)),
                );
              }
              await fixture.replaceExternal({});
              expect(await prefs.reload(), isEmpty);
              await prefs.dispose();
              await Future.wait([names.done, added.done]);
            });

            test('decoder errors still allow removal notifications', () async {
              final failure = StateError('Cannot decode');
              final output = expectStreamEvents(
                prefs.observe<String>('name', (raw) {
                  if (raw == null) return null;
                  if (asynchronous) return Future<String?>.error(failure);
                  throw failure;
                }),
                [emitsError(same(failure)), null],
              );
              await output.firstEvent;
              await fixture.replaceExternal({});
              expect(await prefs.reload(), isEmpty);
              await prefs.dispose();
              await output.done;
            });

            for (final input in <String?>[null, 'remove']) {
              test(
                'does not repeat encoded removals for ${input == null ? 'null' : 'non-null'} input',
                () async {
                  final output = expectStreamEvents(
                    prefs.getStringStream('name'),
                    ['Ada', anything],
                  );
                  await output.firstEvent;
                  var encoderCalls = 0;
                  await prefs.write<String>('name', input, (_) {
                    encoderCalls++;
                    return asynchronous ? Future<Object?>.value(null) : null;
                  });
                  expect(encoderCalls, 1);
                  expect(await adapter.containsKey('name'), isFalse);
                  await prefs.reload();
                  await prefs.reload();
                  await prefs.dispose();
                  await output.done;
                },
              );
            }

            test('tracks null inputs encoded to stored values', () async {
              await prefs.clear();
              final output = expectStreamEvents(
                prefs.getStringStream('added'),
                [null, anything, null],
              );
              await output.firstEvent;
              var encoderCalls = 0;
              await prefs.write<String>('added', null, (_) {
                encoderCalls++;
                return asynchronous ? Future<Object?>.value('Grace') : 'Grace';
              });
              expect(encoderCalls, 1);
              expect(await adapter.getString('added'), 'Grace');
              await fixture.replaceExternal({});
              expect(await prefs.reload(), isEmpty);
              await prefs.dispose();
              await output.done;
            });
          });
        }
      });

      group('typed updates', () {
        test('accept async transformers and remove null results', () async {
          await prefs.setBool('bool', true);
          await prefs.setDouble('double', 1.5);
          await prefs.updateBool('bool', (value) async => !value!);
          await prefs.updateDouble('double', (value) async => value! + 0.5);
          await prefs.updateInt('count', (value) async => value! + 1);
          await prefs.updateString('name', (value) async => '$value!');
          await prefs.updateStringList(
            'tags',
            (value) async => [...value!, 'two'],
          );
          expect(await prefs.readAll((_, raw) => raw), {
            'bool': false,
            'double': 2.0,
            'count': 2,
            'name': 'Ada!',
            'tags': ['one', 'two'],
          });
          await prefs.updateString('name', (_) async => null);
          expect(await prefs.containsKey('name'), isFalse);
        });
      });
    });
  }
}

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

Future<void> _expectNext<T>(StreamIterator<T> iterator, Object? value) async {
  expect(await iterator.moveNext().timeout(const Duration(seconds: 5)), isTrue);
  expect(iterator.current, value);
}

class _PreferencesFixture {
  final SharedPreferencesLike adapter;
  final RxSharedPreferences prefs;
  final Future<void> Function(Map<String, Object> values) replaceExternal;

  _PreferencesFixture(this.adapter, this.prefs, this.replaceExternal);

  static Future<_PreferencesFixture> create(_AdapterKind kind) async {
    if (kind == _AdapterKind.legacy) {
      SharedPreferences.setMockInitialValues(
        _initialValues.map((key, value) => MapEntry('flutter.$key', value)),
      );
      final raw = await SharedPreferences.getInstance();
      return _PreferencesFixture(
        await SharedPreferencesAdapter.from(raw),
        RxSharedPreferences(raw),
        (values) async {
          SharedPreferencesStorePlatform.instance =
              InMemorySharedPreferencesStore.withData(
                values.map((key, value) => MapEntry('flutter.$key', value)),
              );
        },
      );
    }

    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(_initialValues);
    final external = SharedPreferencesAsyncAdapter(SharedPreferencesAsync());
    final SharedPreferencesLike adapter;
    final RxSharedPreferences prefs;
    if (kind == _AdapterKind.async) {
      final raw = SharedPreferencesAsync();
      adapter = SharedPreferencesAsyncAdapter(raw);
      prefs = RxSharedPreferences.async(raw);
    } else {
      final raw = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );
      adapter = await SharedPreferencesWithCacheAdapter.from(raw);
      prefs = RxSharedPreferences.withCache(raw);
    }
    return _PreferencesFixture(adapter, prefs, (values) async {
      await external.clear();
      for (final entry in values.entries) {
        await external.write(entry.key, entry.value, (value) => value);
      }
    });
  }
}
