import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rx_shared_preferences/src/impl/shared_preferences_adapter.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'fake_shared_prefs_store.dart';
import 'model/user.dart';

void main() {
  group('SharedPreferencesAdapter', () {
    const prefix = 'flutter.';

    late FakeSharedPreferencesStore store;
    late SharedPreferencesAdapter adapter;

    setUp(() async {
      store = FakeSharedPreferencesStore(kTestValues);
      SharedPreferencesStorePlatform.instance = store;

      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      adapter = SharedPreferencesAdapter.from(preferences)
          as SharedPreferencesAdapter;

      store.log.clear();
    });

    test('from Future<SharedPreferences>', () {
      final value =
          SharedPreferencesAdapter.from(SharedPreferences.getInstance());
      expect(value, isA<Future<SharedPreferencesAdapter>>());
    });

    test('from SharedPreferences', () async {
      final value =
          SharedPreferencesAdapter.from(await SharedPreferences.getInstance());
      expect(value, isA<SharedPreferencesAdapter>());
    });

    test('reading', () async {
      expect(await adapter.getString('String'), kTestValues['flutter.String']);
      expect(await adapter.getBool('bool'), kTestValues['flutter.bool']);
      expect(await adapter.getInt('int'), kTestValues['flutter.int']);
      expect(await adapter.getDouble('double'), kTestValues['flutter.double']);
      expect(await adapter.getStringList('List'), kTestValues['flutter.List']);
      expect(await adapter.getString('String'), kTestValues['flutter.String']);
      expect(await adapter.getBool('bool'), kTestValues['flutter.bool']);
      expect(await adapter.getInt('int'), kTestValues['flutter.int']);
      expect(await adapter.getDouble('double'), kTestValues['flutter.double']);
      expect(await adapter.getStringList('List'), kTestValues['flutter.List']);
      expect(
        await adapter.read<User>(
          'User',
          userFromString,
        ),
        user1,
      );
      expect(
        await adapter.read<User>(
          'User',
          userFromStringFuture,
        ),
        user1,
      );

      expect(store.log, <Matcher>[]);
    });

    test('writing', () async {
      await Future.wait([
        adapter.setString('String', kTestValues2['flutter.String'] as String),
        adapter.setBool('bool', kTestValues2['flutter.bool'] as bool),
        adapter.setInt('int', kTestValues2['flutter.int'] as int),
        adapter.setDouble('double', kTestValues2['flutter.double'] as double),
        adapter.setStringList(
            'List', kTestValues2['flutter.List'] as List<String>),
        adapter.write<User>(
          'User',
          user2,
          userToString,
        ),
        adapter.write<User>(
          'User',
          user2,
          userToStringFuture,
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
          isMethodCall('setValue', arguments: <dynamic>[
            'String',
            'flutter.User',
            kTestValues2['flutter.User'],
          ]),
        ],
      );
      store.log.clear();

      expect(await adapter.getString('String'), kTestValues2['flutter.String']);
      expect(await adapter.getBool('bool'), kTestValues2['flutter.bool']);
      expect(await adapter.getInt('int'), kTestValues2['flutter.int']);
      expect(await adapter.getDouble('double'), kTestValues2['flutter.double']);
      expect(await adapter.getStringList('List'), kTestValues2['flutter.List']);
      expect(
        await adapter.read<User>(
          'User',
          userFromString,
        ),
        user2,
      );
      expect(
        await adapter.read<User>(
          'User',
          userFromStringFuture,
        ),
        user2,
      );
      expect(store.log, equals(<MethodCall>[]));

      await runZonedGuarded(
        () => adapter.write('unsupported_type', 1, (v) => <String>{}),
        (e, s) => expect(e, isA<PlatformException>()),
      );

      store.failedMethod = const MethodCall('setValue');
      for (final f in [
        adapter.setString('String', kTestValues2['flutter.String'] as String),
        adapter.setBool('bool', kTestValues2['flutter.bool'] as bool),
        adapter.setInt('int', kTestValues2['flutter.int'] as int),
        adapter.setDouble('double', kTestValues2['flutter.double'] as double),
        adapter.setStringList(
            'List', kTestValues2['flutter.List'] as List<String>),
        adapter.write<User>(
          'User',
          user2,
          userToString,
        ),
        adapter.write<User>(
          'User',
          user2,
          userToStringFuture,
        ),
      ]) {
        expect(f, throwsPlatformException);
      }
    });

    test('removing', () async {
      const key = 'testKey';
      await adapter.setString(key, null);
      await adapter.setBool(key, null);
      await adapter.setInt(key, null);
      await adapter.setDouble(key, null);
      await adapter.setStringList(key, null);
      await adapter.remove(key);
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
      expect(adapter.remove(key), throwsPlatformException);
    });

    test('containsKey', () async {
      const key = 'testKey';

      expect(false, await adapter.containsKey(key));

      await adapter.setString(key, 'test');
      expect(true, await adapter.containsKey(key));
    });

    test('clearing', () async {
      await adapter.clear();
      expect(await adapter.getString('String'), null);
      expect(await adapter.getBool('bool'), null);
      expect(await adapter.getInt('int'), null);
      expect(await adapter.getDouble('double'), null);
      expect(await adapter.getStringList('List'), null);
      expect(store.log, <Matcher>[isMethodCall('clear', arguments: null)]);

      store.failedMethod = const MethodCall('clear');
      expect(adapter.clear(), throwsPlatformException);
    });

    test('reloading', () async {
      await adapter.setString(
          'String', kTestValues['flutter.String'] as String);
      expect(await adapter.getString('String'), kTestValues['flutter.String']);

      SharedPreferences.setMockInitialValues(kTestValues2);
      expect(await adapter.getString('String'), kTestValues['flutter.String']);

      await adapter.reload();
      expect(await adapter.getString('String'), kTestValues2['flutter.String']);

      SharedPreferencesStorePlatform.instance =
          store = FakeSharedPreferencesStore(kTestValues2)
            ..failedMethod = const MethodCall('getAll');
      expect(adapter.reload(), throwsPlatformException);
    });

    test('writing copy of strings list', () async {
      final myList = <String>[];
      await adapter.setStringList('myList', myList);
      myList.add('foobar');

      final cachedList = await adapter.getStringList('myList');
      expect(cachedList, <String>[]);

      cachedList!.add('foobar2');

      expect(await adapter.getStringList('myList'), <String>[]);
    });

    test('getKeys', () async {
      final keys = await adapter.getKeys();
      final expected = Set.of(
        kTestValues.keys.map(
          (s) => s.substring(prefix.length),
        ),
      );

      expect(
        const SetEquality<String>().equals(keys, expected),
        isTrue,
      );
    });

    test('readAll', () async {
      expect(
        await adapter.readAll(),
        kTestValues.map(
          (key, value) => MapEntry(
            key.substring(prefix.length),
            value,
          ),
        ),
      );

      SharedPreferences.setMockInitialValues(kTestValues2);
      await adapter.reload();

      expect(
        await adapter.readAll(),
        kTestValues2.map(
          (key, value) => MapEntry(
            key.substring(prefix.length),
            value,
          ),
        ),
      );
    });
  });
}
