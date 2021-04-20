import 'package:example/home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_provider/flutter_provider.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// Singleton instance for app
  final rxPrefs = RxSharedPreferences(
    SharedPreferences.getInstance(),
    kReleaseMode ? null : RxSharedPreferencesDefaultLogger(),
  );

  runApp(
    Provider.value(
      rxPrefs,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RxSharedPreferences example',
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}
