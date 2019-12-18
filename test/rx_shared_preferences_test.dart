import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('$RxSharedPreferences is like to $SharedPreferences', () {
    const kTestValues = <String, dynamic>{
      'flutter.String': 'hello world',
      'flutter.bool': true,
      'flutter.int': 42,
      'flutter.double': 3.14159,
      'flutter.List': <String>['foo', 'bar'],
    };

    const kTestValues2 = <String, dynamic>{
      'flutter.String': 'goodbye world',
      'flutter.bool': false,
      'flutter.int': 1337,
      'flutter.double': 2.71828,
      'flutter.List': <String>['baz', 'quox'],
    };

    FakeSharedPreferencesStore store;
    RxSharedPreferences rxPrefs;

    setUp(() async {
      store = FakeSharedPreferencesStore(kTestValues);
      SharedPreferencesStorePlatform.instance = store;

      rxPrefs = RxSharedPreferences(await SharedPreferences.getInstance());

      store.log.clear();
    });

    tearDown(() async {
      await rxPrefs.clear();
    });

    test('reading', () async {
      expect(await rxPrefs.get('String'), kTestValues['flutter.String']);
      expect(await rxPrefs.get('bool'), kTestValues['flutter.bool']);
      expect(await rxPrefs.get('int'), kTestValues['flutter.int']);
      expect(await rxPrefs.get('double'), kTestValues['flutter.double']);
      expect(await rxPrefs.get('List'), kTestValues['flutter.List']);
      expect(await rxPrefs.getString('String'), kTestValues['flutter.String']);
      expect(await rxPrefs.getBool('bool'), kTestValues['flutter.bool']);
      expect(await rxPrefs.getInt('int'), kTestValues['flutter.int']);
      expect(await rxPrefs.getDouble('double'), kTestValues['flutter.double']);
      expect(await rxPrefs.getStringList('List'), kTestValues['flutter.List']);
      expect(store.log, <Matcher>[]);
    });

    test('writing', () async {
      await Future.wait(<Future<bool>>[
        rxPrefs.setString('String', kTestValues2['flutter.String']),
        rxPrefs.setBool('bool', kTestValues2['flutter.bool']),
        rxPrefs.setInt('int', kTestValues2['flutter.int']),
        rxPrefs.setDouble('double', kTestValues2['flutter.double']),
        rxPrefs.setStringList('List', kTestValues2['flutter.List'])
      ]);
      expect(
        store.log,
        <Matcher>[
          isMethodCall('setValue', arguments: <dynamic>[
            'String',
            'flutter.String',
            kTestValues2['flutter.String'],
          ]),
          isMethodCall('setValue', arguments: <dynamic>[
            'Bool',
            'flutter.bool',
            kTestValues2['flutter.bool'],
          ]),
          isMethodCall('setValue', arguments: <dynamic>[
            'Int',
            'flutter.int',
            kTestValues2['flutter.int'],
          ]),
          isMethodCall('setValue', arguments: <dynamic>[
            'Double',
            'flutter.double',
            kTestValues2['flutter.double'],
          ]),
          isMethodCall('setValue', arguments: <dynamic>[
            'StringList',
            'flutter.List',
            kTestValues2['flutter.List'],
          ]),
        ],
      );
      store.log.clear();

      expect(await rxPrefs.getString('String'), kTestValues2['flutter.String']);
      expect(await rxPrefs.getBool('bool'), kTestValues2['flutter.bool']);
      expect(await rxPrefs.getInt('int'), kTestValues2['flutter.int']);
      expect(await rxPrefs.getDouble('double'), kTestValues2['flutter.double']);
      expect(await rxPrefs.getStringList('List'), kTestValues2['flutter.List']);
      expect(store.log, equals(<MethodCall>[]));
    });

    test('removing', () async {
      const String key = 'testKey';
      await rxPrefs.setString(key, null);
      await rxPrefs.setBool(key, null);
      await rxPrefs.setInt(key, null);
      await rxPrefs.setDouble(key, null);
      await rxPrefs.setStringList(key, null);
      await rxPrefs.remove(key);
      expect(
          store.log,
          List<Matcher>.filled(
            6,
            isMethodCall(
              'remove',
              arguments: 'flutter.$key',
            ),
            growable: true,
          ));
    });

    test('containsKey', () async {
      const String key = 'testKey';

      expect(false, await rxPrefs.containsKey(key));

      await rxPrefs.setString(key, 'test');
      expect(true, await rxPrefs.containsKey(key));
    });

    test('clearing', () async {
      await rxPrefs.clear();
      expect(await rxPrefs.getString('String'), null);
      expect(await rxPrefs.getBool('bool'), null);
      expect(await rxPrefs.getInt('int'), null);
      expect(await rxPrefs.getDouble('double'), null);
      expect(await rxPrefs.getStringList('List'), null);
      expect(store.log, <Matcher>[isMethodCall('clear', arguments: null)]);
    });

    test('reloading', () async {
      await rxPrefs.setString('String', kTestValues['flutter.String']);
      expect(await rxPrefs.getString('String'), kTestValues['flutter.String']);

      SharedPreferences.setMockInitialValues(kTestValues2);
      expect(await rxPrefs.getString('String'), kTestValues['flutter.String']);

      await rxPrefs.reload();
      expect(await rxPrefs.getString('String'), kTestValues2['flutter.String']);
    });

    test('writing copy of strings list', () async {
      final List<String> myList = <String>[];
      await rxPrefs.setStringList("myList", myList);
      myList.add("foobar");

      final List<String> cachedList = await rxPrefs.getStringList('myList');
      expect(cachedList, <String>[]);

      cachedList.add("foobar2");

      expect(await rxPrefs.getStringList('myList'), <String>[]);
    });
  });

  group('Test Stream', () {
    const Map<String, dynamic> kTestValues = <String, dynamic>{
      'flutter.String': 'hello world',
      'flutter.bool': true,
      'flutter.int': 42,
      'flutter.double': 3.14159,
      'flutter.List': <String>['foo', 'bar'],
    };

    RxSharedPreferences rxPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(kTestValues);

      rxPrefs = RxSharedPreferences(
        await SharedPreferences.getInstance(),
        const DefaultLogger(),
      );
    });

    tearDown(() async {
      await rxPrefs.clear();
      await rxPrefs.dispose();
    });

    test(
      'Stream will emit error when read value is not valid type, or emit null when value is not set',
      () async {
        final Stream<int> intStream =
            rxPrefs.getIntStream('bool'); // Actual: Stream<bool>
        await expectLater(
          intStream,
          emitsAnyOf([
            isNull,
            emitsError(isInstanceOf<TypeError>()),
          ]),
        );

        final Stream<List<String>> listStringStream =
            rxPrefs.getStringListStream('String'); // Actual: Stream<String>
        await expectLater(
          listStringStream,
          emitsAnyOf([
            isNull,
            emitsError(isInstanceOf<TypeError>()),
          ]),
        );

        final Stream<int> noSuchStream =
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
            rxPrefs.getStream('No such key'),
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
        final Stream<bool> streamBool = rxPrefs.getBoolStream('bool');
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
        final Stream<double> streamDouble = rxPrefs.getDoubleStream('double');
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
        final Stream<int> streamInt = rxPrefs.getIntStream('int');
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
        final Stream<String> streamString = rxPrefs.getStringStream('String');
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
        final Stream<List<String>> streamListString =
            rxPrefs.getStringListStream('List');
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

      final later = expectLater(
        stream,
        emitsInOrder(
          [
            anything,
            <String>['before', 'dispose'],
            emitsDone,
            neverEmits(anything),
          ],
        ),
      );

      await rxPrefs.setStringList(
        'List',
        <String>['before', 'dispose'],
      );

      // delay
      await Future.delayed(const Duration(microseconds: 500));

      await rxPrefs.dispose();

      // not emit but persisted
      await rxPrefs.setStringList(
        'List',
        <String>['after', 'dispose'],
      );

      // working fine
      expect(
        await rxPrefs.getStringList('List'),
        <String>['after', 'dispose'],
      );

      await later;
    });

    test('Emit null when clearing', () async {
      final Stream<List<String>> stream = rxPrefs.getStringListStream('List');

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
          'flutter.List': ['AFTER RELOAD']
        },
      );
      await rxPrefs.reload(); // emits ['AFTER RELOAD']

      await rxPrefs.setStringList('List', ['WORKING 1']); // emits ['WORKING']

      SharedPreferencesStorePlatform.instance =
          InMemorySharedPreferencesStore.withData({
        'flutter.List': ['WORKING 2'],
      });
      await rxPrefs.reload(); // emits ['WORKING']

      await later;
    });
  });
}

/// Fake Shared Preferences Store
class FakeSharedPreferencesStore implements SharedPreferencesStorePlatform {
  final InMemorySharedPreferencesStore backend;
  final log = <MethodCall>[];

  FakeSharedPreferencesStore(Map<String, dynamic> data)
      : backend = InMemorySharedPreferencesStore.withData(data);

  @override
  bool get isMock => true;

  @override
  Future<bool> clear() {
    log.add(MethodCall('clear'));
    return backend.clear();
  }

  @override
  Future<Map<String, Object>> getAll() {
    log.add(MethodCall('getAll'));
    return backend.getAll();
  }

  @override
  Future<bool> remove(String key) {
    log.add(MethodCall('remove', key));
    return backend.remove(key);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    log.add(MethodCall('setValue', [valueType, key, value]));
    return backend.setValue(valueType, key, value);
  }
}
