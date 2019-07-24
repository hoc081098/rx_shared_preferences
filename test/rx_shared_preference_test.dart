import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preference/rx_shared_preference.dart';
import 'package:rxdart/src/observables/observable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_api/test_api.dart' show TypeMatcher;

void main() {
  group('$RxSharedPreferences is like to $SharedPreferences', () {
    const MethodChannel channel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );

    const Map<String, dynamic> kTestValues = <String, dynamic>{
      'flutter.String': 'hello world',
      'flutter.bool': true,
      'flutter.int': 42,
      'flutter.double': 3.14159,
      'flutter.List': <String>['foo', 'bar'],
    };

    const Map<String, dynamic> kTestValues2 = <String, dynamic>{
      'flutter.String': 'goodbye world',
      'flutter.bool': false,
      'flutter.int': 1337,
      'flutter.double': 2.71828,
      'flutter.List': <String>['baz', 'quox'],
    };

    final List<MethodCall> log = <MethodCall>[];
    RxSharedPreferences rxSharedPreferences;

    setUp(() async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'getAll') {
          return kTestValues;
        }
        if (methodCall.method.startsWith('set') ||
            methodCall.method == 'clear') {
          return true;
        }
        return null;
      });
      rxSharedPreferences =
          RxSharedPreferences(await SharedPreferences.getInstance());
      log.clear();
    });

    tearDown(() async {
      await rxSharedPreferences.clear();
    });

    test('reading', () async {
      expect(
        await rxSharedPreferences.get('String'),
        kTestValues['flutter.String'],
      );
      expect(
        await rxSharedPreferences.get('bool'),
        kTestValues['flutter.bool'],
      );
      expect(
        await rxSharedPreferences.get('int'),
        kTestValues['flutter.int'],
      );
      expect(
        await rxSharedPreferences.get('double'),
        kTestValues['flutter.double'],
      );
      expect(
        await rxSharedPreferences.get('List'),
        kTestValues['flutter.List'],
      );
      expect(
        await rxSharedPreferences.getString('String'),
        kTestValues['flutter.String'],
      );
      expect(
        await rxSharedPreferences.getBool('bool'),
        kTestValues['flutter.bool'],
      );
      expect(
        await rxSharedPreferences.getInt('int'),
        kTestValues['flutter.int'],
      );
      expect(
        await rxSharedPreferences.getDouble('double'),
        kTestValues['flutter.double'],
      );
      expect(
        await rxSharedPreferences.getStringList('List'),
        kTestValues['flutter.List'],
      );
      expect(log, <Matcher>[]);
    });

    test('writing', () async {
      await Future.wait(<Future<bool>>[
        rxSharedPreferences.setString('String', kTestValues2['flutter.String']),
        rxSharedPreferences.setBool('bool', kTestValues2['flutter.bool']),
        rxSharedPreferences.setInt('int', kTestValues2['flutter.int']),
        rxSharedPreferences.setDouble('double', kTestValues2['flutter.double']),
        rxSharedPreferences.setStringList('List', kTestValues2['flutter.List'])
      ]);
      expect(
        log,
        <Matcher>[
          isMethodCall('setString', arguments: <String, dynamic>{
            'key': 'flutter.String',
            'value': kTestValues2['flutter.String']
          }),
          isMethodCall('setBool', arguments: <String, dynamic>{
            'key': 'flutter.bool',
            'value': kTestValues2['flutter.bool']
          }),
          isMethodCall('setInt', arguments: <String, dynamic>{
            'key': 'flutter.int',
            'value': kTestValues2['flutter.int']
          }),
          isMethodCall('setDouble', arguments: <String, dynamic>{
            'key': 'flutter.double',
            'value': kTestValues2['flutter.double']
          }),
          isMethodCall('setStringList', arguments: <String, dynamic>{
            'key': 'flutter.List',
            'value': kTestValues2['flutter.List']
          }),
        ],
      );
      log.clear();

      expect(
        await rxSharedPreferences.getString('String'),
        kTestValues2['flutter.String'],
      );
      expect(
        await rxSharedPreferences.getBool('bool'),
        kTestValues2['flutter.bool'],
      );
      expect(
        await rxSharedPreferences.getInt('int'),
        kTestValues2['flutter.int'],
      );
      expect(
        await rxSharedPreferences.getDouble('double'),
        kTestValues2['flutter.double'],
      );
      expect(
        await rxSharedPreferences.getStringList('List'),
        kTestValues2['flutter.List'],
      );
      expect(log, equals(<MethodCall>[]));
    });

    test('removing', () async {
      const String key = 'testKey';
      rxSharedPreferences
        ..setString(key, null)
        ..setBool(key, null)
        ..setInt(key, null)
        ..setDouble(key, null)
        ..setStringList(key, null);
      await rxSharedPreferences.remove(key);
      expect(
          log,
          List<Matcher>.filled(
            6,
            isMethodCall(
              'remove',
              arguments: <String, dynamic>{'key': 'flutter.$key'},
            ),
            growable: true,
          ));
    });

    test('containsKey', () async {
      const String key = 'testKey';

      expect(false, await rxSharedPreferences.containsKey(key));

      rxSharedPreferences.setString(key, 'test');
      expect(true, await rxSharedPreferences.containsKey(key));
    });

    test('clearing', () async {
      await rxSharedPreferences.clear();
      expect(
        await rxSharedPreferences.getString('String'),
        null,
      );
      expect(
        await rxSharedPreferences.getBool('bool'),
        null,
      );
      expect(
        await rxSharedPreferences.getInt('int'),
        null,
      );
      expect(
        await rxSharedPreferences.getDouble('double'),
        null,
      );
      expect(
        await rxSharedPreferences.getStringList('List'),
        null,
      );
      expect(log, <Matcher>[isMethodCall('clear', arguments: null)]);
    });

    test('reloading', () async {
      await rxSharedPreferences.setString(
          'String', kTestValues['flutter.String']);
      expect(await rxSharedPreferences.getString('String'),
          kTestValues['flutter.String']);

      SharedPreferences.setMockInitialValues(kTestValues2);
      expect(await rxSharedPreferences.getString('String'),
          kTestValues2['flutter.String']);

      await rxSharedPreferences.reload();
      expect(await rxSharedPreferences.getString('String'),
          kTestValues2['flutter.String']);
    });

    group('mocking', () {
      const String _key = 'dummy';
      const String _prefixedKey = 'flutter.' + _key;

      test('test 1', () async {
        SharedPreferences.setMockInitialValues(
            <String, dynamic>{_prefixedKey: 'my string'});

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final RxSharedPreferences rxPrefs = RxSharedPreferences(prefs);

        final String value = prefs.getString(_key);
        final String valueReadFromRxPrefs = await rxPrefs.getString(_key);

        expect(value, 'my string');
        expect(value, valueReadFromRxPrefs);
      });

      test('test 2', () async {
        SharedPreferences.setMockInitialValues(
            <String, dynamic>{_prefixedKey: 'my other string'});

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final RxSharedPreferences rxPrefs = RxSharedPreferences(prefs);

        final String value = prefs.getString(_key);
        final String valueReadFromRxPrefs = await rxPrefs.getString(_key);

        expect(value, 'my other string');
        expect(value, valueReadFromRxPrefs);
      });
    });

    test('writing copy of strings list', () async {
      final List<String> myList = <String>[];
      await rxSharedPreferences.setStringList("myList", myList);
      myList.add("foobar");

      final List<String> cachedList =
          await rxSharedPreferences.getStringList('myList');
      expect(cachedList, <String>[]);

      cachedList.add("foobar2");

      expect(await rxSharedPreferences.getStringList('myList'), <String>[]);
    });
  });

  group('Test Stream', () {
    const MethodChannel channel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );

    const Map<String, dynamic> kTestValues = <String, dynamic>{
      'flutter.String': 'hello world',
      'flutter.bool': true,
      'flutter.int': 42,
      'flutter.double': 3.14159,
      'flutter.List': <String>['foo', 'bar'],
    };

    final List<MethodCall> log = <MethodCall>[];
    RxSharedPreferences rxSharedPreferences;

    setUp(() async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'getAll') {
          return kTestValues;
        }
        if (methodCall.method.startsWith('set') ||
            methodCall.method == 'clear' ||
            methodCall.method == 'remove') {
          return true;
        }
        return null;
      });
      rxSharedPreferences =
          RxSharedPreferences(await SharedPreferences.getInstance());
      log.clear();
    });

    test(
      'Observable will emit error when read value is not valid type, or emit null when value is not set',
      () async {
        final Observable<int> intObservable = rxSharedPreferences
            .getIntObservable('bool'); // Actual: Observable<bool>
        await expectLater(
          intObservable,
          emitsAnyOf([
            isNull,
            emitsError(const TypeMatcher<TypeError>()),
          ]),
        );

        final Observable<List<String>> listStringObservable =
            rxSharedPreferences.getStringListObservable(
                'String'); // Actual: Observable<String>

        await expectLater(
          listStringObservable,
          emitsAnyOf([
            isNull,
            emitsError(const TypeMatcher<TypeError>()),
          ]),
        );

        final Observable<int> noSuchObservable =
            rxSharedPreferences.getIntObservable(
                '@@@@@@@@@@@String'); // Actual: Observable<String>

        await expectLater(
          noSuchObservable,
          emits(isNull),
        );
      },
    );

    test(
      'Observable will emit value as soon as possible after listen',
      () async {
        await Future.wait([
          expectLater(
            rxSharedPreferences.getIntObservable('int'),
            emits(anything),
          ),
          expectLater(
            rxSharedPreferences.getBoolObservable('bool'),
            emits(anything),
          ),
          expectLater(
            rxSharedPreferences.getDoubleObservable('double'),
            emits(anything),
          ),
          expectLater(
            rxSharedPreferences.getStringObservable('String'),
            emits(anything),
          ),
          expectLater(
            rxSharedPreferences.getStringListObservable('List'),
            emits(anything),
          ),
          expectLater(
            rxSharedPreferences.getObservable('No such key'),
            emits(isNull),
          ),
        ]);
      },
    );

    test(
      'Observable will emit value as soon as possible after listen,'
      ' and will emit value when value associated with key change',
      () async {
        ///
        /// Bool
        ///
        final Observable<bool> streamBool =
            rxSharedPreferences.getBoolObservable('bool');
        final expectStreamBoolFuture = expectLater(
          streamBool,
          emitsInOrder([anything, false, true, false, true, false]),
        );
        await rxSharedPreferences.setBool('bool', false);
        await rxSharedPreferences.setBool('bool', true);
        await rxSharedPreferences.setBool('bool', false);
        await rxSharedPreferences.setBool('bool', true);
        await rxSharedPreferences.setBool('bool', false);

        ///
        /// Double
        ///
        final Observable<double> streamDouble =
            rxSharedPreferences.getDoubleObservable('double');
        final expectStreamDoubleFuture = expectLater(
          streamDouble,
          emitsInOrder([anything, 0.3333, 1, 2, isNull, 3, isNull, 4]),
        );
        await rxSharedPreferences.setDouble('double', 0.3333);
        await rxSharedPreferences.setDouble('double', 1);
        await rxSharedPreferences.setDouble('double', 2);
        await rxSharedPreferences.setDouble('double', null);
        await rxSharedPreferences.setDouble('double', 3);
        await rxSharedPreferences.remove('double');
        await rxSharedPreferences.setDouble('double', 4);

        ///
        /// Int
        ///
        final Observable<int> streamInt =
            rxSharedPreferences.getIntObservable('int');
        final expectStreamIntFuture = expectLater(
          streamInt,
          emitsInOrder([anything, 1, isNull, 2, 3, isNull, 3, 2, 1]),
        );
        await rxSharedPreferences.setInt('int', 1);
        await rxSharedPreferences.setInt('int', null);
        await rxSharedPreferences.setInt('int', 2);
        await rxSharedPreferences.setInt('int', 3);
        await rxSharedPreferences.remove('int');
        await rxSharedPreferences.setInt('int', 3);
        await rxSharedPreferences.setInt('int', 2);
        await rxSharedPreferences.setInt('int', 1);

        ///
        /// String
        ///
        final Observable<String> streamString =
            rxSharedPreferences.getStringObservable('String');
        final expectStreamStringFuture = expectLater(
          streamString,
          emitsInOrder([anything, 'h', 'e', 'l', 'l', 'o', isNull]),
        );
        await rxSharedPreferences.setString('String', 'h');
        await rxSharedPreferences.setString('String', 'e');
        await rxSharedPreferences.setString('String', 'l');
        await rxSharedPreferences.setString('String', 'l');
        await rxSharedPreferences.setString('String', 'o');
        await rxSharedPreferences.setString('String', null);

        ///
        /// List<String>
        ///
        final Observable<List<String>> streamListString =
            rxSharedPreferences.getStringListObservable('List');
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
            <String>['AFTER RELOAD'],
            <String>['AFTER RELOAD'],
            ['WORKING']
          ]),
        );
        await rxSharedPreferences.setStringList('List', ['1', '2', '3']);
        await rxSharedPreferences.setStringList('List', ['1', '2', '3', '4']);
        await rxSharedPreferences
            .setStringList('List', ['1', '2', '3', '4', '5']);
        await rxSharedPreferences.setStringList('List', ['1', '2', '3', '4']);
        await rxSharedPreferences.setStringList('List', ['1', '2', '3']);
        await rxSharedPreferences.setStringList('List', ['1', '2']);
        await rxSharedPreferences.setStringList('List', ['1']);
        await rxSharedPreferences.setStringList('List', []);
        await rxSharedPreferences.remove('List');
        await rxSharedPreferences.setStringList('List', ['done']);
        await rxSharedPreferences.setStringList('List', ['AFTER RELOAD']);

        ///
        /// Test reloading
        ///
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return {
              'flutter.List': ['AFTER RELOAD']
            };
          }
          if (methodCall.method.startsWith('set')) {
            return true;
          }
          return null;
        });
        await rxSharedPreferences.reload();
        rxSharedPreferences.setStringList('List', ['WORKING']);

        await Future.wait([
          expectStreamBoolFuture,
          expectStreamDoubleFuture,
          expectStreamIntFuture,
          expectStreamStringFuture,
          expectStreamListStringFuture,
        ]);
      },
    );
  });
}
