import 'dart:async';

/// Map stream and reject null
class MapNotNullStreamTransformer<T, R> extends StreamTransformerBase<T, R> {
  final R Function(T) _mapper;

  /// Construct a [MapNotNullStreamTransformer] with [mapper]
  MapNotNullStreamTransformer(R Function(T) mapper)
      : assert(mapper != null),
        _mapper = mapper;

  @override
  Stream<R> bind(Stream<T> stream) {
    StreamController<R> controller;
    StreamSubscription<T> subscription;

    void onDone() {
      if (!controller.isClosed) {
        controller.close();
      }
    }

    void onListen() {
      subscription = stream.listen(
        (data) {
          R mappedValue;

          try {
            mappedValue = _mapper(data);
          } catch (e, s) {
            controller.addError(e, s);
            return;
          }

          if (mappedValue != null) {
            controller.add(mappedValue);
          }
        },
        onError: controller.addError,
        onDone: onDone,
      );
    }

    void onCancel() => subscription.cancel();

    if (stream.isBroadcast) {
      controller = StreamController<R>.broadcast(
        sync: true,
        onListen: onListen,
        onCancel: onCancel,
      );
    } else {
      controller = StreamController<R>(
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

/// Map stream and reject null extension
/// ### Example
///
///     Stream.fromIterable([1, 'two', 3, 'four'])
///       .mapNotNull((i) => i is int ? i : null)
///       .listen(print); // prints 1, 3
///
/// #### as opposed to:
///
///     Stream.fromIterable([1, 'two', 3, 'four'])
///       .map((i) => i is int ? i : null)
///       .where((i) => i != null)
///       .listen(print); // prints 1, 3
extension MapNotNullStreamExtension<T> on Stream<T> {
  /// Map stream and reject null
  Stream<R> mapNotNull<R>(R Function(T) mapper) =>
      transform(MapNotNullStreamTransformer(mapper));
}
