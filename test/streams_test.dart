import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  group('RxSharedPreferences stream tests', () {
    const kTestValues = <String, Object>{
      'flutter.String': 'hello world',
      'flutter.bool': true,
      'flutter.int': 42,
      'flutter.double': 3.14159,
      'flutter.List': <String>['foo', 'bar'],
    };

    late RxSharedPreferences rxPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(kTestValues);

      rxPrefs = RxSharedPreferences(
        await SharedPreferences.getInstance(),
        const RxSharedPreferencesDefaultLogger(),
      );
    });

    tearDown(() {
      try {
        rxPrefs.dispose();
      } catch (_) {}
    });

    test(
      'Stream will emit error when read value is not valid type, or emit null when value is not set',
      () async {
        final intStream = rxPrefs.getIntStream('bool'); // Actual: Stream<bool>
        await expectLater(
          intStream,
          emitsAnyOf([
            isNull,
            emitsError(isInstanceOf<TypeError>()),
          ]),
        );

        final listStringStream =
            rxPrefs.getStringListStream('String'); // Actual: Stream<String>
        await expectLater(
          listStringStream,
          emitsAnyOf([
            isNull,
            emitsError(isInstanceOf<TypeError>()),
          ]),
        );

        final noSuchStream =
            rxPrefs.getIntStream('###String'); // Actual: Stream<String>

        await expectLater(
          noSuchStream,
          emits(isNull),
        );
      },
    );

    test(
      'Stream will emit value as soon as possible after listen',
      () async {
        await Future.wait([
          expectLater(
            rxPrefs.getIntStream('int'),
            emits(anything),
          ),
          expectLater(
            rxPrefs.getBoolStream('bool'),
            emits(anything),
          ),
          expectLater(
            rxPrefs.getDoubleStream('double'),
            emits(anything),
          ),
          expectLater(
            rxPrefs.getStringStream('String'),
            emits(anything),
          ),
          expectLater(
            rxPrefs.getStringListStream('List'),
            emits(anything),
          ),
          expectLater(
            rxPrefs.getObjectStream('No such key'),
            emits(isNull),
          ),
          expectLater(
            rxPrefs.getObjectStream('No such key', (o) => null),
            emits(isNull),
          ),
        ]);
      },
    );

    test(
      'Stream will emit value as soon as possible after listen,'
      ' and will emit value when value associated with key change',
      () async {
        ///
        /// Bool
        ///
        final streamBool = rxPrefs.getBoolStream('bool');
        final expectStreamBoolFuture = expectLater(
          streamBool,
          emitsInOrder([anything, false, true, false, true, false]),
        );
        await rxPrefs.setBool('bool', false);
        await rxPrefs.setBool('bool', true);
        await rxPrefs.setBool('bool', false);
        await rxPrefs.setBool('bool', true);
        await rxPrefs.setBool('bool', false);

        ///
        /// Double
        ///
        final streamDouble = rxPrefs.getDoubleStream('double');
        final expectStreamDoubleFuture = expectLater(
          streamDouble,
          emitsInOrder([anything, 0.3333, 1, 2, isNull, 3, isNull, 4]),
        );
        await rxPrefs.setDouble('double', 0.3333);
        await rxPrefs.setDouble('double', 1);
        await rxPrefs.setDouble('double', 2);
        await rxPrefs.setDouble('double', null);
        await rxPrefs.setDouble('double', 3);
        await rxPrefs.remove('double');
        await rxPrefs.setDouble('double', 4);

        ///
        /// Int
        ///
        final streamInt = rxPrefs.getIntStream('int');
        final expectStreamIntFuture = expectLater(
          streamInt,
          emitsInOrder([anything, 1, isNull, 2, 3, isNull, 3, 2, 1]),
        );
        await rxPrefs.setInt('int', 1);
        await rxPrefs.setInt('int', null);
        await rxPrefs.setInt('int', 2);
        await rxPrefs.setInt('int', 3);
        await rxPrefs.remove('int');
        await rxPrefs.setInt('int', 3);
        await rxPrefs.setInt('int', 2);
        await rxPrefs.setInt('int', 1);

        ///
        /// String
        ///
        final streamString = rxPrefs.getStringStream('String');
        final expectStreamStringFuture = expectLater(
          streamString,
          emitsInOrder([anything, 'h', 'e', 'l', 'l', 'o', isNull]),
        );
        await rxPrefs.setString('String', 'h');
        await rxPrefs.setString('String', 'e');
        await rxPrefs.setString('String', 'l');
        await rxPrefs.setString('String', 'l');
        await rxPrefs.setString('String', 'o');
        await rxPrefs.setString('String', null);

        ///
        /// List<String>
        ///
        final streamListString = rxPrefs.getStringListStream('List');
        final expectStreamListStringFuture = expectLater(
          streamListString,
          emitsInOrder([
            anything,
            <String>['1', '2', '3'],
            <String>['1', '2', '3', '4'],
            <String>['1', '2', '3', '4', '5'],
            <String>['1', '2', '3', '4'],
            <String>['1', '2', '3'],
            <String>['1', '2'],
            <String>['1'],
            <String>[],
            isNull,
            <String>['done'],
          ]),
        );
        await rxPrefs.setStringList('List', ['1', '2', '3']);
        await rxPrefs.setStringList('List', ['1', '2', '3', '4']);
        await rxPrefs.setStringList('List', ['1', '2', '3', '4', '5']);
        await rxPrefs.setStringList('List', ['1', '2', '3', '4']);
        await rxPrefs.setStringList('List', ['1', '2', '3']);
        await rxPrefs.setStringList('List', ['1', '2']);
        await rxPrefs.setStringList('List', ['1']);
        await rxPrefs.setStringList('List', []);
        await rxPrefs.remove('List');
        await rxPrefs.setStringList('List', ['done']);

        await Future.wait([
          expectStreamBoolFuture,
          expectStreamDoubleFuture,
          expectStreamIntFuture,
          expectStreamStringFuture,
          expectStreamListStringFuture,
        ]);
      },
    );

    test('Does not emit anything after disposed', () async {
      final stream = rxPrefs.getStringListStream('List');

      const expected = [
        anything,
        ['before', 'dispose', '1'],
        ['before', 'dispose', '2'],
      ];
      var index = 0;
      final result = <bool>[];
      stream.listen(
        (data) => result.add(index == 0 ? true : data == expected[index++]),
      );

      for (final v in expected.skip(1)) {
        await rxPrefs.setStringList(
          'List',
          v as List<String>,
        );
        await Future.delayed(Duration.zero);
      }

      // delay
      await Future.delayed(const Duration(microseconds: 500));
      await rxPrefs.dispose();
      await Future.delayed(Duration.zero);

      try {
        // cannot use anymore
        await rxPrefs.setStringList(
          'List',
          <String>['after', 'dispose'],
        );
      } catch (e) {
        expect(e, isStateError);
      }

      try {
        // cannot use anymore
        expect(
          await rxPrefs.getStringList('List'),
          <String>['after', 'dispose'],
        );
      } catch (e) {
        expect(e, isStateError);
      }

      // timeout is 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      expect(result.length, expected.length);
      expect(result.every((element) => element), isTrue);
    });

    test('Emit null when clearing', () async {
      final stream = rxPrefs.getStringListStream('List');

      final later = expectLater(
        stream,
        emitsInOrder(
          [
            anything,
            isNull,
          ],
        ),
      );

      await rxPrefs.clear();

      await later;
    });

    test('Emit value when reloading', () async {
      final stream = rxPrefs.getStringListStream('List');

      final later = expectLater(
        stream,
        emitsInOrder(
          [
            anything,
            ['AFTER RELOAD'],
            ['WORKING 1'],
            ['WORKING 2'],
          ],
        ),
      );

      SharedPreferencesStorePlatform.instance =
          InMemorySharedPreferencesStore.withData(
        {
          'flutter.List': <Object?>['AFTER RELOAD']
        },
      );
      await rxPrefs.reload(); // emits ['AFTER RELOAD']

      await rxPrefs.setStringList('List', ['WORKING 1']); // emits ['WORKING']

      SharedPreferencesStorePlatform.instance =
          InMemorySharedPreferencesStore.withData({
        'flutter.List': <Object?>['WORKING 2'],
      });
      await rxPrefs.reload(); // emits ['WORKING']

      await later;
    });

    test('Emit keys', () async {
      final keysStream = rxPrefs.getKeysStream();

      final future = expectLater(
        keysStream,
        emitsInOrder([
          anything,
          anything,
          anything,
          anything,
        ]),
      );

      await rxPrefs.setInt('int', 0);
      await rxPrefs.setDouble('double', 0);
      await rxPrefs.setString('String', '');

      await future;
    });

    test('RxSharedPreferences.getInstance', () async {
      RxSharedPreferences rxPrefs1;
      expect(
        identical(
          RxSharedPreferences.getInstance(),
          rxPrefs1 = RxSharedPreferences.getInstance(),
        ),
        isTrue,
      );

      // dispose rxPrefs
      await rxPrefs.dispose();

      RxSharedPreferences rxPrefs2;
      expect(
        identical(
          RxSharedPreferences.getInstance(),
          rxPrefs2 = RxSharedPreferences.getInstance(),
        ),
        isTrue,
      );
      // ignore: unnecessary_null_comparison
      expect(identical(rxPrefs1, rxPrefs2) && rxPrefs1 != null, isTrue);

      // dispose default singleton
      await RxSharedPreferences.getInstance().dispose();

      RxSharedPreferences rxPrefs3;
      expect(
        identical(
          RxSharedPreferences.getInstance(),
          rxPrefs3 = RxSharedPreferences.getInstance(),
        ),
        isTrue,
      );
      // ignore: unnecessary_null_comparison
      expect(identical(rxPrefs3, rxPrefs1) && rxPrefs3 != null, isFalse);
    });

    test('Stream is single-subscription stream', () {
      final stream = rxPrefs.getStringListStream('List');
      expect(stream.isBroadcast, isFalse);
      stream.listen(null);
      expect(() => stream.listen(null), throwsStateError);
    });

    test('rx', () async {
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.rx.getStringStream('key'), emits(anything));
      expect(prefs.rx.getStringListStream('flutter.List'), emits(anything));
      expect(prefs.rx.getDoubleStream('flutter.double'), emits(anything));

      final old = prefs.rx;
      expect(identical(old, prefs.rx), true);

      await old.dispose();
      expect(identical(old, prefs.rx), false);
    });

    test('executeUpdateBool', () async {
      final initial = kTestValues['flutter.bool'] as bool;
      final expected = !initial;

      expect(
        rxPrefs.getBoolStream('bool'),
        emitsInOrder(<Object>[anything, expected]),
      );
      expect(await rxPrefs.getBool('bool'), initial);
      // ignore: deprecated_member_use_from_same_package
      await rxPrefs.executeUpdateBool('bool', (s) => !s!);
      expect(await rxPrefs.getBool('bool'), expected);
    });

    test('updateBool', () async {
      final initial = kTestValues['flutter.bool'] as bool;
      final expected = !initial;

      expect(
        rxPrefs.getBoolStream('bool'),
        emitsInOrder(<Object>[anything, expected]),
      );
      expect(await rxPrefs.getBool('bool'), initial);
      await rxPrefs.updateBool('bool', (s) => !s!);
      expect(await rxPrefs.getBool('bool'), expected);
    });

    test('executeUpdateDouble', () async {
      final initial = kTestValues['flutter.double'] as double;
      final expected = initial + 1;

      expect(
        rxPrefs.getDoubleStream('double'),
        emitsInOrder(<Object>[anything, expected]),
      );
      expect(await rxPrefs.getDouble('double'), initial);
      // ignore: deprecated_member_use_from_same_package
      await rxPrefs.executeUpdateDouble('double', (s) => s! + 1);
      expect(await rxPrefs.getDouble('double'), expected);
    });

    test('updateDouble', () async {
      final initial = kTestValues['flutter.double'] as double;
      final expected = initial + 1;

      expect(
        rxPrefs.getDoubleStream('double'),
        emitsInOrder(<Object>[anything, expected]),
      );
      expect(await rxPrefs.getDouble('double'), initial);
      await rxPrefs.updateDouble('double', (s) => s! + 1);
      expect(await rxPrefs.getDouble('double'), expected);
    });

    test('executeUpdateInt', () async {
      final initial = kTestValues['flutter.int'] as int;
      final expected = initial + 1;

      expect(
        rxPrefs.getIntStream('int'),
        emitsInOrder(<Object>[anything, expected]),
      );
      expect(await rxPrefs.getInt('int'), initial);
      // ignore: deprecated_member_use_from_same_package
      await rxPrefs.executeUpdateInt('int', (s) => s! + 1);
      expect(await rxPrefs.getInt('int'), expected);
    });

    test('updateInt', () async {
      final initial = kTestValues['flutter.int'] as int;
      final expected = initial + 1;

      expect(
        rxPrefs.getIntStream('int'),
        emitsInOrder(<Object>[anything, expected]),
      );
      expect(await rxPrefs.getInt('int'), initial);
      await rxPrefs.updateInt('int', (s) => s! + 1);
      expect(await rxPrefs.getInt('int'), expected);
    });

    test('executeUpdateString', () async {
      final initial = kTestValues['flutter.String'] as String;
      final expected = '${initial}1';

      expect(
        rxPrefs.getStringStream('String'),
        emitsInOrder(<Object>[anything, expected]),
      );
      expect(await rxPrefs.getString('String'), initial);
      // ignore: deprecated_member_use_from_same_package
      await rxPrefs.executeUpdateString('String', (s) => '${s!}1');
      expect(await rxPrefs.getString('String'), expected);
    });

    test('updateString', () async {
      final initial = kTestValues['flutter.String'] as String;
      final expected = '${initial}1';

      expect(
        rxPrefs.getStringStream('String'),
        emitsInOrder(<Object>[anything, expected]),
      );
      expect(await rxPrefs.getString('String'), initial);
      await rxPrefs.updateString('String', (s) => '${s!}1');
      expect(await rxPrefs.getString('String'), expected);
    });

    test('executeUpdateStringList', () async {
      final initial = kTestValues['flutter.List'] as List<String>;
      final expected = [...initial, '1'];

      expect(
        rxPrefs.getStringListStream('List'),
        emitsInOrder(<Object>[anything, expected]),
      );
      expect(await rxPrefs.getStringList('List'), initial);
      // ignore: deprecated_member_use_from_same_package
      await rxPrefs.executeUpdateStringList('List', (s) => [...s!, '1']);
      expect(await rxPrefs.getStringList('List'), expected);
    });

    test('updateStringList', () async {
      final initial = kTestValues['flutter.List'] as List<String>;
      final expected = [...initial, '1'];

      expect(
        rxPrefs.getStringListStream('List'),
        emitsInOrder(<Object>[anything, expected]),
      );
      expect(await rxPrefs.getStringList('List'), initial);
      await rxPrefs.updateStringList('List', (s) => [...s!, '1']);
      expect(await rxPrefs.getStringList('List'), expected);
    });
  });
}
