import 'dart:async';

///
class ShareValueStream<T> extends Stream<T> {
  final Stream<T> _source;

  _Event<T> _lastEvent;
  StreamSubscription<T> _subscription;
  StreamController<T> _controller;

  ///
  ShareValueStream(this._source) {
    _controller =
        StreamController<T>.broadcast(sync: true, onCancel: _onCancel);
  }

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    if (_controller == null || _controller.isClosed) {
      final event = _lastEvent;
      if (event == null) {
        // Return a dummy subscription backed by nothing, since
        // it will only ever send one done event.
        return Stream<T>.empty().listen(null, onDone: onDone);
      }
      if (event is _DataEvent<T>) {
        return Stream.value(event.data).listen(onData, onDone: onDone);
      }
      if (event is _ErrorEvent<T>) {
        return Stream.error(event.e, event.st).listen(
          null,
          onError: onError,
          onDone: onDone,
        );
      }
      throw StateError('Invalid state: controller has been closed!');
    }

    _subscription ??= _source.listen(
      (data) {
        _lastEvent = _DataEvent(data);
        _controller.add(data);
      },
      onError: (e, st) {
        _lastEvent = _ErrorEvent(e, st);
        _controller.addError(e, st);
      },
      onDone: _controller.close,
    );

    cancelOnError = identical(true, cancelOnError);
    return _controller.stream._startWith(() => _lastEvent).listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
        );
  }

  void _onCancel() {
    final subscription = _subscription;
    _subscription = null;
    _controller = null;
    subscription?.cancel();
  }
}

abstract class _Event<T> {}

class _DataEvent<T> implements _Event<T> {
  final T data;

  _DataEvent(this.data);
}

class _ErrorEvent<T> implements _Event<T> {
  final dynamic e;
  final StackTrace st;

  _ErrorEvent(this.e, this.st);
}

extension _StartWithStreamExtension<T> on Stream<T> {
  Stream<T> _startWith(_Event<T> Function() eventFactory) {
    StreamController<T> controller;
    StreamSubscription<T> subscription;

    void onListen() {
      final event = eventFactory();

      if (event is _DataEvent<T>) {
        controller.add(event.data);
      } else if (event is _ErrorEvent<T>) {
        controller.addError(event.e, event.st);
      }

      subscription = listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
    }

    onCancel() => subscription.cancel();

    if (isBroadcast) {
      controller = StreamController<T>.broadcast(
        sync: true,
        onListen: onListen,
        onCancel: onCancel,
      );
    } else {
      controller = StreamController<T>(
        sync: true,
        onListen: onListen,
        onPause: ([Future resumeSignal]) => subscription.pause(resumeSignal),
        onResume: () => subscription.resume(),
        onCancel: onCancel,
      );
    }

    return controller.stream;
  }
}

///
extension ShareValueStreamExtension<T> on Stream<T> {
  ///
  Stream<T> shareValue() => ShareValueStream(this);
}
