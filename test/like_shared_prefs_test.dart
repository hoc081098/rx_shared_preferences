import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'fake_shared_prefs_store.dart';
import 'model/user.dart';

void main() {
  group('RxSharedPreferences is like to SharedPreferences', () {
    late FakeSharedPreferencesStore store;
    late RxSharedPreferences rxPrefs;

    setUp(() async {
      store = FakeSharedPreferencesStore(kTestValues);
      SharedPreferencesStorePlatform.instance = store;

      rxPrefs = RxSharedPreferences(
        await SharedPreferences.getInstance(),
        const RxSharedPreferencesDefaultLogger(),
      );
      await rxPrefs.reload();

      store.log.clear();
    });

    tearDown(() async {
      store.failedMethod = null;
      await rxPrefs.clear();
    });

    test('reading', () async {
      expect(await rxPrefs.getString('String'), kTestValues['flutter.String']);
      expect(await rxPrefs.getBool('bool'), kTestValues['flutter.bool']);
      expect(await rxPrefs.getInt('int'), kTestValues['flutter.int']);
      expect(await rxPrefs.getDouble('double'), kTestValues['flutter.double']);
      expect(await rxPrefs.getStringList('List'), kTestValues['flutter.List']);
      expect(await rxPrefs.getString('String'), kTestValues['flutter.String']);
      expect(await rxPrefs.getBool('bool'), kTestValues['flutter.bool']);
      expect(await rxPrefs.getInt('int'), kTestValues['flutter.int']);
      expect(await rxPrefs.getDouble('double'), kTestValues['flutter.double']);
      expect(await rxPrefs.getStringList('List'), kTestValues['flutter.List']);
      expect(
        await rxPrefs.read<User>(
          'User',
          (s) => s == null ? null : User.fromJson(jsonDecode(s as String)),
        ),
        user1,
      );
      expect(
        await rxPrefs.getObject('Some key'),
        isNull,
      );
      expect(
        await rxPrefs.getObject('Some key', (o) => 'fallback'),
        'fallback',
      );

      expect(store.log, <Matcher>[]);
    });

    test('writing', () async {
      await Future.wait([
        rxPrefs.setString('String', kTestValues2['flutter.String'] as String),
        rxPrefs.setBool('bool', kTestValues2['flutter.bool'] as bool),
        rxPrefs.setInt('int', kTestValues2['flutter.int'] as int),
        rxPrefs.setDouble('double', kTestValues2['flutter.double'] as double),
        rxPrefs.setStringList(
            'List', kTestValues2['flutter.List'] as List<String>),
        rxPrefs.write<User>(
          'User',
          user2,
          (u) => jsonEncode(u),
        ),
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
          isMethodCall('setValue', arguments: <dynamic>[
            'String',
            'flutter.User',
            kTestValues2['flutter.User'],
          ]),
        ],
      );
      store.log.clear();

      expect(await rxPrefs.getString('String'), kTestValues2['flutter.String']);
      expect(await rxPrefs.getBool('bool'), kTestValues2['flutter.bool']);
      expect(await rxPrefs.getInt('int'), kTestValues2['flutter.int']);
      expect(await rxPrefs.getDouble('double'), kTestValues2['flutter.double']);
      expect(await rxPrefs.getStringList('List'), kTestValues2['flutter.List']);
      expect(
        await rxPrefs.read<User>(
          'User',
          (s) => s == null ? null : User.fromJson(jsonDecode(s as String)),
        ),
        user2,
      );
      expect(store.log, equals(<MethodCall>[]));

      await expectLater(
        rxPrefs.write('unsupported_type', 1, (v) => <String>{}),
        throwsA(isA<StateError>()),
      );

      store.failedMethod = const MethodCall('setValue');
      for (final f in [
        rxPrefs.setString('String', kTestValues2['flutter.String'] as String),
        rxPrefs.setBool('bool', kTestValues2['flutter.bool'] as bool),
        rxPrefs.setInt('int', kTestValues2['flutter.int'] as int),
        rxPrefs.setDouble('double', kTestValues2['flutter.double'] as double),
        rxPrefs.setStringList(
            'List', kTestValues2['flutter.List'] as List<String>),
        rxPrefs.write<User>(
          'User',
          user2,
          (u) => jsonEncode(u),
        ),
      ]) {
        expect(f, throwsPlatformException);
      }
    });

    test('removing', () async {
      const key = 'testKey';
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

      store.failedMethod = const MethodCall('remove');
      expect(rxPrefs.remove(key), throwsPlatformException);
    });

    test('containsKey', () async {
      const key = 'testKey';

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

      store.failedMethod = const MethodCall('clear');
      expect(rxPrefs.clear(), throwsPlatformException);
    });

    test('reloading', () async {
      await rxPrefs.setString(
          'String', kTestValues['flutter.String'] as String);
      expect(await rxPrefs.getString('String'), kTestValues['flutter.String']);

      SharedPreferences.setMockInitialValues(kTestValues2);
      expect(await rxPrefs.getString('String'), kTestValues['flutter.String']);

      await rxPrefs.reload();
      expect(await rxPrefs.getString('String'), kTestValues2['flutter.String']);

      SharedPreferencesStorePlatform.instance =
          store = FakeSharedPreferencesStore(kTestValues2)
            ..failedMethod = const MethodCall('getAll');
      expect(rxPrefs.reload(), throwsPlatformException);
    });

    test('writing copy of strings list', () async {
      final myList = <String>[];
      await rxPrefs.setStringList('myList', myList);
      myList.add('foobar');

      final cachedList = await rxPrefs.getStringList('myList');
      expect(cachedList, <String>[]);

      cachedList!.add('foobar2');

      expect(await rxPrefs.getStringList('myList'), <String>[]);
    });

    test('getKeys', () async {
      const _prefix = 'flutter.';
      final keys = await rxPrefs.getKeys();
      final expected = Set.of(
        kTestValues.keys.map(
          (s) => s.substring(_prefix.length),
        ),
      );

      expect(
        const SetEquality<String>().equals(keys, expected),
        isTrue,
      );
    });

    test('readAll', () async {
      const _prefix = 'flutter.';

      expect(
        await rxPrefs.readAll(),
        kTestValues.map(
          (key, value) => MapEntry(
            key.substring(_prefix.length),
            value,
          ),
        ),
      );

      SharedPreferences.setMockInitialValues(kTestValues2);
      await rxPrefs.reload();

      expect(
        await rxPrefs.readAll(),
        kTestValues2.map(
          (key, value) => MapEntry(
            key.substring(_prefix.length),
            value,
          ),
        ),
      );
    });
  });
}
