import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

      rxPrefs = RxSharedPreferences(await SharedPreferences.getInstance());
    });

    tearDown(() async => await rxPrefs.dispose());

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

    test('RxSharedPreferences.getInstance', () {
      expect(
        identical(
          RxSharedPreferences.getInstance(),
          RxSharedPreferences.getInstance(),
        ),
        isTrue,
      );
    });
  });
}
