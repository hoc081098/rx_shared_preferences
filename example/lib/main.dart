import 'package:example/home.dart';
import 'package:example/loggers.dart';
import 'package:example/rx_prefs_provider.dart';
import 'package:flutter/material.dart';
import 'package:rx_shared_preference/rx_shared_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  /// Singleton instance for app
  final rxPrefs = RxSharedPreferences(
    SharedPreferences.getInstance(),
    defaultLogger,
  );
  runApp(
    RxPrefsProvider(
      rxPrefs: rxPrefs,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rx Shared Preference example',
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}
