import 'dart:async';

import 'package:collection/collection.dart';
import 'package:example/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_provider/flutter_provider.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

const listKey = 'com.hoc.list';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final compositeSubscription = CompositeSubscription();

  final controller = StreamController<void>();
  late final StateStream<ViewState> list$ = controller.stream
      .startWith(null)
      .switchMap((_) => context.rxPrefs
          .getStringListStream(listKey)
          .map((list) => ViewState.success(list ?? const []))
          .onErrorReturnWith((e, s) => ViewState.failure(e, s)))
      .debug(identifier: '<<STATE>>', log: debugPrint)
      .publishState(ViewState.loading)
    ..connect().addTo(compositeSubscription);

  @override
  void initState() {
    super.initState();
    final _ = list$; // evaluation lazy property.
  }

  @override
  void dispose() {
    compositeSubscription.dispose();
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RxSharedPreferences example'),
      ),
      body: StreamBuilder<ViewState>(
        stream: list$,
        initialData: list$.value,
        builder: (context, snapshot) {
          final state = snapshot.requireData;

          final asyncError = state.error;
          if (asyncError != null) {
            final error = asyncError.error;
            debugPrint('Error: $error');
            debugPrint('StackTrace: ${asyncError.stackTrace}');

            return Center(
              child: Text(
                'Error: $error',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            );
          }

          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final list = state.items;
          if (list.isEmpty) {
            return Center(
              child: Text(
                'Empty',
                style: Theme.of(context).textTheme.titleLarge,
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
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Builder(
            builder: (context) {
              return FloatingActionButton(
                onPressed: () => context.showDialogAdd(),
                tooltip: 'Add a string',
                child: const Icon(Icons.add),
              );
            },
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () async {
              await context.rxPrefs.reload();
              controller.add(null);
            },
            tooltip: 'Reload',
            child: const Icon(Icons.refresh),
          )
        ],
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

@immutable
class ViewState {
  final List<String> items;
  final bool isLoading;
  final AsyncError? error;

  static const loading = ViewState._([], true, null);

  const ViewState._(this.items, this.isLoading, this.error);

  const ViewState.success(List<String> items) : this._(items, false, null);

  ViewState.failure(Object e, StackTrace s)
      : this._([], false, AsyncError(e, s));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewState &&
          runtimeType == other.runtimeType &&
          const ListEquality<String>().equals(items, other.items) &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => items.hashCode ^ isLoading.hashCode ^ error.hashCode;

  @override
  String toString() =>
      'ViewState{items.length: ${items.length}, isLoading: $isLoading, error: $error}';
}
