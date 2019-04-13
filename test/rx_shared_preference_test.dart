// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preference/rx_shared_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        return null;
      });
      rxSharedPreferences =
          RxSharedPreferences(await SharedPreferences.getInstance());
      log.clear();
    });

    tearDown(() {
      rxSharedPreferences.clear();
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

    test('mocking', () async {
      // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
      // https://github.com/flutter/flutter/issues/26431
      // ignore: strong_mode_implicit_dynamic_method
      expect(await channel.invokeMethod('getAll'), kTestValues);
      SharedPreferences.setMockInitialValues(kTestValues2);
      // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
      // https://github.com/flutter/flutter/issues/26431
      // ignore: strong_mode_implicit_dynamic_method
      expect(await channel.invokeMethod('getAll'), kTestValues2);
    });

    test('Test Observer Stream', () async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method.startsWith('set') ||
            methodCall.method == 'clear') {
          return true;
        }
        return null;
      });

      await expectLater(
          rxSharedPreferences.getObservable('No such key'), emits(isNull));

      final streamBool = rxSharedPreferences.getBoolObservable('bool').share();
      await expectLater(streamBool, emits(true));
      await rxSharedPreferences.setBool('bool', false);
      await expectLater(streamBool, emits(false));

      final streamDouble =
          rxSharedPreferences.getDoubleObservable('double').share();
      await expectLater(streamDouble, emits(3.14159));
      await rxSharedPreferences.setDouble('double', 0.3333);
      await expectLater(streamDouble, emits(0.3333));

      final dynamicStream = rxSharedPreferences.getObservable('int').share();
      await expectLater(dynamicStream, emits(42));
      await rxSharedPreferences.setDouble('int', 69);
      await expectLater(dynamicStream, emits(69));
      await rxSharedPreferences.remove('int');
      await expectLater(dynamicStream, emits(isNull));
      expect(await rxSharedPreferences.get('int'), isNull);
      await rxSharedPreferences.setInt('int', 2);

      await rxSharedPreferences.clear();
      await Future.wait([
        expectLater(dynamicStream, emits(isNull)),
        expectLater(streamDouble, emits(isNull)),
        expectLater(streamBool, emits(isNull)),
      ]);
    });
  });
}
