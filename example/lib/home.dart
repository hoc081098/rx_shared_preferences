import 'dart:async';

import 'package:example/dialog.dart';
import 'package:example/rx_prefs_provider.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

const key = 'com.hoc.list';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ValueObservable<List<String>> _list$;
  StreamSubscription<List<String>> _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_subscription == null) {
      final list$ = RxPrefsProvider.of(context)
          .getStringListObservable(key)
          .publishValue();
      _subscription = list$.connect();
      _list$ = list$;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: StreamBuilder<List<String>>(
        stream: _list$,
        initialData: _list$.value,
        builder: (context, snapshot) {
          final list = snapshot.data ?? <String>[];
          return ListView.builder(
            itemCount: list.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(list[index]),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle),
                  onPressed: () => showDialogRemove(list[index], context),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () => showDialogAdd(context),
            child: Icon(Icons.add),
            tooltip: 'Add a string',
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
