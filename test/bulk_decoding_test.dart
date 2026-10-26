import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rx_shared_preferences/src/impl/async/shared_preferences_async_adapter.dart';
import 'package:rx_shared_preferences/src/impl/async/shared_preferences_with_cache_adapter.dart';
import 'package:rx_shared_preferences/src/impl/legacy/shared_preferences_adapter.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

enum _AdapterKind { legacy, async, withCache }

const _initialValues = <String, Object>{
  'count': 1,
  'name': 'Ada',
  'tags': <String>['one'],
};

void main() {
  for (final kind in _AdapterKind.values) {
    group('${kind.name} bulk decoding', () {
      late _PreferencesFixture fixture;
      late SharedPreferencesLike adapter;
      late RxSharedPreferences prefs;

      setUp(() async {
        fixture = await _PreferencesFixture.create(kind);
        adapter = fixture.adapter;
        prefs = fixture.prefs;
      });

      tearDown(() => prefs.dispose());

      test(
        'identity decoder reads raw entries through the public API',
        () async {
          expect(await adapter.readAll((_, raw) => raw), _initialValues);
          expect(await prefs.readAll((_, raw) => raw), _initialValues);
          expect(await prefs.getKeys(), _initialValues.keys.toSet());
        },
      );

      test(
        'entry decoder receives keys and supports mixed async results',
        () async {
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
        },
      );

      test('empty storage does not invoke the decoder', () async {
        await adapter.clear();
        expect(
          await adapter.readAll((_, _) => fail('No entries to decode')),
          isEmpty,
        );
      });

      test(
        'a synchronous decoder failure completes the future with an error',
        () async {
          final failure = StateError('Cannot decode');
          final result = adapter.readAll((_, _) => throw failure);
          await expectLater(result, throwsA(same(failure)));
          expect(await adapter.readAll((_, raw) => raw), _initialValues);
        },
      );

      test(
        'an asynchronous decoder failure returns no partial result',
        () async {
          final failure = StateError('Cannot decode name');
          await expectLater(
            adapter.readAll(
              (key, raw) =>
                  key == 'name' ? Future<Object?>.error(failure) : raw,
            ),
            throwsA(same(failure)),
          );
        },
      );

      test(
        'decoders use a snapshot when they mutate the backing store',
        () async {
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
        },
      );

      test(
        'bulk maps are independent and cached string lists remain copies',
        () async {
          final result = await adapter.readAll((_, raw) => raw);
          if (kind != _AdapterKind.async) {
            (result['tags'] as List<String>).add('changed');
          }
          result['count'] = 99;
          expect(await adapter.getStringList('tags'), ['one']);
          expect(await adapter.getInt('count'), 1);
        },
      );

      test(
        'encoded null removes an entry while decoded null retains it',
        () async {
          final decoded = await adapter.readAll((_, _) => null);
          expect(decoded.keys, unorderedEquals(_initialValues.keys));
          expect(decoded.values, everyElement(isNull));

          await adapter.setString('name', null);
          final raw = await adapter.readAll((_, value) => value);
          expect(raw.containsKey('name'), isFalse);
          expect(await adapter.containsKey('name'), isFalse);
        },
      );

      test(
        'observeAll decodes initial data and each successful mutation',
        () async {
          await prefs.clear();
          final iterator = StreamIterator(
            prefs.observeAll((key, raw) => '$key=$raw'),
          );
          addTearDown(iterator.cancel);

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
        },
      );

      test('observeAll retains null decoding results', () async {
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
          'observeAll recovers after ${asynchronous ? 'async' : 'sync'} decoder errors',
          () async {
            final failure = StateError('Cannot decode count');
            final initial = Completer<void>();
            final failed = Completer<void>();
            final recovered = Completer<void>();
            final data = <Map<String, Object?>>[];
            final errors = <Object>[];
            final subscription = prefs
                .observeAll((key, raw) {
                  if (key == 'count' && raw == 2) {
                    if (asynchronous) {
                      return Future<Object?>.error(failure);
                    }
                    throw failure;
                  }
                  return raw;
                })
                .listen(
                  (value) {
                    data.add(value);
                    if (!initial.isCompleted) initial.complete();
                    if (value['count'] == 3) recovered.complete();
                  },
                  onError: (Object error) {
                    errors.add(error);
                    failed.complete();
                  },
                );
            addTearDown(subscription.cancel);

            await initial.future;
            await prefs.setInt('count', 2);
            await failed.future;
            await prefs.setInt('count', 3);
            await recovered.future;

            expect(errors, [same(failure)]);
            expect(data.map((value) => value['count']), [1, 3]);
          },
        );
      }

      test(
        'observeAll waits for async decoding before processing later reads',
        () async {
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
        },
      );

      test('observeAll is single-subscription', () async {
        final stream = prefs.observeAll((_, raw) => raw);
        expect(stream.isBroadcast, isFalse);
        final subscription = stream.listen(null);
        expect(() => stream.listen(null), throwsStateError);
        await subscription.cancel();
      });

      test(
        'reload notifies updated, added and removed keys using raw values',
        () async {
          final count = StreamIterator(prefs.getIntStream('count'));
          final name = StreamIterator(prefs.getStringStream('name'));
          final added = StreamIterator(prefs.getStringStream('added'));
          final keys = StreamIterator(prefs.getKeysStream());
          final decoded = StreamIterator(
            prefs.observeAll((key, raw) => '$key=$raw'),
          );
          for (final iterator in [count, name, added, keys, decoded]) {
            addTearDown(iterator.cancel);
            expect(await iterator.moveNext(), isTrue);
          }

          await fixture.replaceExternal({'count': 2, 'added': 'Grace'});
          expect(await prefs.reload(), {'count': 2, 'added': 'Grace'});
          await _expectNext(count, 2);
          await _expectNext(name, null);
          await _expectNext(added, 'Grace');
          await _expectNext(keys, {'count', 'added'});
          await _expectNext(decoded, {
            'count': 'count=2',
            'added': 'added=Grace',
          });
        },
      );

      test(
        'all typed update helpers accept asynchronous transformers',
        () async {
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
        },
      );
    });
  }
}

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
