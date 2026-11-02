import 'dart:async';

import 'package:example/flutter_secure_storage_snippet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = FlutterSecureStorage();
  late FlutterSecureStorageAdapter adapter;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'token': 'initial',
      'count': '2',
    });
    adapter = const FlutterSecureStorageAdapter(secureStorage);
  });

  group('FlutterSecureStorageAdapter', () {
    test('reads strings, missing values and custom decoded values', () async {
      expect(await adapter.getString('token'), 'initial');
      expect(await adapter.getString('missing'), isNull);
      expect(await adapter.containsKey('token'), isTrue);
      expect(await adapter.containsKey('missing'), isFalse);
      expect(
        await adapter.read<int>('count', (raw) => int.parse(raw as String)),
        2,
      );
      expect(
        await adapter.read<int>(
          'count',
          (raw) async => int.parse(raw as String),
        ),
        2,
      );
      await expectLater(adapter.getInt('count'), throwsA(isA<TypeError>()));
    });

    test('writes strings and custom encoded values', () async {
      await adapter.setString('token', 'updated');
      await adapter.write<int>('count', 3, (value) => value?.toString());
      expect(await secureStorage.readAll(), {'token': 'updated', 'count': '3'});

      await adapter.write<int>('count', 4, (value) async => value?.toString());
      expect(await secureStorage.read(key: 'count'), '4');
    });

    test('removes null values, individual keys and all entries', () async {
      await adapter.setString('token', null);
      expect(await adapter.containsKey('token'), isFalse);
      await adapter.remove('count');
      expect(await secureStorage.readAll(), isEmpty);

      await adapter.setString('token', 'replacement');
      await adapter.clear();
      expect(await secureStorage.readAll(), isEmpty);
    });

    for (final asynchronous in [false, true]) {
      final mode = asynchronous ? 'async' : 'sync';

      test('removes non-null values with a $mode null encoding', () async {
        await adapter.write<String>(
          'token',
          'remove this value',
          (_) => asynchronous ? Future<Object?>.value(null) : null,
        );
        expect(await adapter.containsKey('token'), isFalse);
      });

      test(
        'rejects $mode unsupported encodings without changing data',
        () async {
          await expectLater(
            () => adapter.write<int>(
              'count',
              3,
              (value) => asynchronous ? Future<Object?>.value(value) : value,
            ),
            throwsA(
              isA<PlatformException>()
                  .having(
                    (error) => error.code,
                    'code',
                    SharedPreferencesLike.errorCode,
                  )
                  .having(
                    (error) => error.message,
                    'message',
                    contains('String or null'),
                  ),
            ),
          );
          expect(await secureStorage.read(key: 'count'), '2');
        },
      );

      test('propagates $mode codec errors without changing data', () async {
        final failure = StateError('Codec failed');
        Object? failCodec(Object? _) {
          if (asynchronous) return Future<Object?>.error(failure);
          throw failure;
        }

        await expectLater(
          adapter.read<Object>('token', failCodec),
          throwsA(same(failure)),
        );
        await expectLater(
          () => adapter.write<Object>('token', 'updated', failCodec),
          throwsA(same(failure)),
        );
        expect(await secureStorage.read(key: 'token'), 'initial');
      });

      test('reports $mode bulk errors before other decoders finish', () async {
        final pending = Completer<Object?>();
        final failure = StateError('Cannot decode count');
        Object? observedError;
        final handled = adapter
            .readAll((key, raw) {
              if (key == 'token') return pending.future;
              if (asynchronous) return Future<Object?>.error(failure);
              throw failure;
            })
            .then<void>(
              (_) => fail('A failed bulk read must not return a map'),
              onError: (Object error) {
                observedError = error;
              },
            );
        try {
          await Future<void>.delayed(Duration.zero);
          expect(observedError, same(failure));
          expect(pending.isCompleted, isFalse);
        } finally {
          pending.completeError(StateError('Late decoder failure'));
          await handled;
          await Future<void>.delayed(Duration.zero);
        }
      });
    }

    test(
      'bulk decoding supports key-specific, async and null results',
      () async {
        expect(
          await adapter.readAll(
            (key, raw) => key == 'count'
                ? Future<int>.value(int.parse(raw as String))
                : null,
          ),
          {'token': null, 'count': 2},
        );
        expect(await adapter.reload(), {'token': 'initial', 'count': '2'});

        final raw = await adapter.readAll((_, raw) => raw);
        expect(raw, {'token': 'initial', 'count': '2'});
        raw['token'] = 'changed copy';
        expect(await secureStorage.read(key: 'token'), 'initial');

        await adapter.clear();
        expect(
          await adapter.readAll((_, _) => fail('No entries to decode')),
          isEmpty,
        );
      },
    );

    test('bulk decoding snapshots entries before decoder mutations', () async {
      final mutations = <Future<void>>[];
      final result = await adapter.readAll((key, raw) {
        if (mutations.isEmpty) {
          mutations.addAll([
            adapter.remove('count'),
            adapter.setString('token', 'updated'),
            adapter.setString('added', 'new'),
          ]);
        }
        return raw;
      });
      await Future.wait(mutations);

      expect(result, {'token': 'initial', 'count': '2'});
      expect(await adapter.reload(), {'token': 'updated', 'added': 'new'});
    });
  });

  group('RxSharedPreferences.custom with secure storage', () {
    late RxSharedPreferences prefs;

    setUp(() {
      prefs = RxSharedPreferences.custom(adapter);
      addTearDown(prefs.dispose);
    });

    test('emits initial strings, updates, removals and closure', () async {
      final iterator = StreamIterator(prefs.getStringStream('token'));
      addTearDown(iterator.cancel);
      await _expectNext(iterator, 'initial');

      await prefs.setString('token', 'updated');
      await _expectNext(iterator, 'updated');
      await prefs.updateString('token', (value) async => '$value again');
      await _expectNext(iterator, 'updated again');
      await prefs.setString('token', null);
      await _expectNext(iterator, null);
      await prefs.setString('token', 'replacement');
      await _expectNext(iterator, 'replacement');
      await prefs.remove('token');
      await _expectNext(iterator, null);
      await prefs.dispose();
      expect(await iterator.moveNext(), isFalse);
    });

    test('observes decoded bulk snapshots after writes and clear', () async {
      final iterator = StreamIterator(
        prefs.observeAll(
          (key, raw) => key == 'count' ? int.parse(raw as String) : raw,
        ),
      );
      addTearDown(iterator.cancel);
      await _expectNext(iterator, {'token': 'initial', 'count': 2});

      await prefs.write<int>('count', 3, (value) async => value?.toString());
      await _expectNext(iterator, {'token': 'initial', 'count': 3});
      await prefs.clear();
      await _expectNext(iterator, <String, Object?>{});
    });

    test('reload notifies external writes and removals', () async {
      final iterator = StreamIterator(prefs.getStringStream('token'));
      addTearDown(iterator.cancel);
      await _expectNext(iterator, 'initial');

      await secureStorage.write(key: 'token', value: 'external');
      expect(await prefs.reload(), {'token': 'external', 'count': '2'});
      await _expectNext(iterator, 'external');

      await secureStorage.delete(key: 'token');
      expect(await prefs.reload(), {'count': '2'});
      await _expectNext(iterator, null);
    });
  });
}

Future<void> _expectNext<T>(
  StreamIterator<T> iterator,
  Object? expected,
) async {
  expect(await iterator.moveNext(), isTrue);
  expect(iterator.current, expected);
}
