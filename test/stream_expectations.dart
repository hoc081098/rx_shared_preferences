import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Matches all events through closure and signals when the first event arrives.
({Future<void> firstEvent, Future<void> done}) expectStreamEvents<T>(
  Stream<T> stream,
  Iterable<Object?> events,
) {
  final first = Completer<void>();
  void markFirst() {
    if (!first.isCompleted) first.complete();
  }

  final observed = stream.transform(
    StreamTransformer<T, T>.fromHandlers(
      handleData: (value, sink) {
        sink.add(value);
        markFirst();
      },
      handleError: (error, stackTrace, sink) {
        sink.addError(error, stackTrace);
        markFirst();
      },
      handleDone: (sink) {
        sink.close();
        markFirst();
      },
    ),
  );
  return (
    firstEvent: first.future,
    done: expectLater(observed, emitsInOrder([...events, emitsDone])),
  );
}
