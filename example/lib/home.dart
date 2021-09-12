import 'package:collection/collection.dart';
import 'package:example/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_provider/flutter_provider.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

const key = 'com.hoc.list';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final compositeSubscription = CompositeSubscription();

  late final StateStream<List<String>?> list$ = context.rxPrefs
      .getStringListStream(key)
      .map<List<String>?>((list) => list ?? const <String>[])
      .publishState(
        null,
        equals: const ListEquality<String>().equals,
      )..connect().addTo(compositeSubscription);

  @override
  void initState() {
    super.initState();
    final _ = list$; // evaluation lazy property.
  }

  @override
  void dispose() {
    compositeSubscription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RxSharedPreferences example'),
      ),
      body: StreamBuilder<List<String>?>(
        stream: list$,
        initialData: list$.value,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error!.toString(),
                style: Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
            );
          }

          final list = snapshot.data;

          if (list == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (list.isEmpty) {
            return Center(
              child: Text(
                'Empty',
                style: Theme.of(context).textTheme.headline6,
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = list[index];

              return ListTile(
                title: Text(item),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle),
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
            tooltip: 'Add a string',
            child: const Icon(Icons.add),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

extension BuildContextX on BuildContext {
  RxSharedPreferences get rxPrefs => get();

  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
