import 'dart:async';

import 'package:example/dialog.dart';
import 'package:example/rx_prefs_provider.dart';
import 'package:flutter/material.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

const key = 'com.hoc.list';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ValueStream<List<String>> list$;
  StreamSubscription<List<String>> subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    subscription ??= (list$ =
            context.rxPrefs.getStringListStream(key).shareValue())
        .listen(null);
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: StreamBuilder<List<String>>(
        stream: list$,
        initialData: list$.value,
        builder: (context, snapshot) {
          final list = snapshot.data ?? <String>[];

          return ListView.builder(
            itemCount: list.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = list[index];

              return ListTile(
                title: Text(item),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle),
                  onPressed: () => context.showDialogRemove(item),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () => context.showDialogAdd(),
            child: Icon(Icons.add),
            tooltip: 'Add a string',
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

extension BuildContextX on BuildContext {
  RxSharedPreferences get rxPrefs => RxPrefsProvider.of(this);

  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
