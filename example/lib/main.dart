import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rx_shared_preference/rx_shared_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  final rxSharedPreferences = RxSharedPreferences(
    SharedPreferences.getInstance(),
    (message) => print('[RX_SHARED_PREF] :: $message'),
  );
  runApp(MyApp(rxSharedPreferences));
}

class MyApp extends StatelessWidget {
  final RxSharedPreferences rxSharedPreferences;

  const MyApp(this.rxSharedPreferences);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rx Shared Preference example',
      theme: ThemeData.dark(),
      home: MyHomePage(rxSharedPreferences),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final RxSharedPreferences rxSharedPreferences;

  const MyHomePage(this.rxSharedPreferences);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _key = 'com.hoc.list';

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _textEditingController = TextEditingController();

  RxSharedPreferences _rxSharedPreferences;
  ValueObservable<List<String>> _list$;
  StreamSubscription<List<String>> _subscription;

  @override
  void initState() {
    super.initState();
    _rxSharedPreferences = widget.rxSharedPreferences;
    _initStream();
  }

  void _initStream() {
    final list$ =
        _rxSharedPreferences.getStringListObservable(_key).publishValue();
    _subscription = list$.connect();
    _list$ = list$;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
            physics: BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(list[index]),
                trailing: IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () => _removeString(list[index])),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addString,
        child: Icon(Icons.add),
        tooltip: 'Add string',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _addString() async {
    _textEditingController.text = '';
    final string = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add a string'),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            controller: _textEditingController,
            onSubmitted: (s) {
              print('Submit $s');
              Navigator.of(context).pop(s);
            },
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                print('OK ${_textEditingController.text}');
                Navigator.of(context).pop(_textEditingController.text);
              },
            ),
          ],
        );
      },
    );
    if (string != null) {
      final currentList =
          await _rxSharedPreferences.getStringList(_key) ?? <String>[];
      final newList = List.of(currentList)..add(string);
      final result = await _rxSharedPreferences.setStringList(
        _key,
        newList,
      );
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            result
                ? "Add '$string' successfully"
                : "Add '$string' not successfully",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeString(String needRemove) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove this string'),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    if (remove ?? false) {
      final currentList =
          await _rxSharedPreferences.getStringList(_key) ?? <String>[];
      final newList = List.of(currentList)..remove(needRemove);
      final result = await _rxSharedPreferences.setStringList(
        _key,
        newList,
      );
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            result
                ? "Remove '$needRemove' successfully"
                : "Remove '$needRemove' not successfully",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
