import 'dart:async';

/// Map stream and reject null
class MapNotNullStreamTransformer<T, R> extends StreamTransformerBase<T, R> {
  final StreamTransformer<T, R> _transformer;

  /// Construct a [MapNotNullStreamTransformer] with [mapper]
  MapNotNullStreamTransformer(R Function(T) mapper)
      : _transformer = _buildTransformer(mapper);

  @override
  Stream<R> bind(Stream<T> stream) => _transformer.bind(stream);

  static StreamTransformer<T, R> _buildTransformer<T, R>(R Function(T) mapper) {
    ArgumentError.checkNotNull(mapper, 'mapper');

    return StreamTransformer<T, R>((stream, cancelOnError) {
      StreamController<R> controller;
      StreamSubscription<T> subscription;

      void onDone() {
        if (!controller.isClosed) {
          controller.close();
        }
      }

      controller = StreamController<R>(
        sync: true,
        onListen: () {
          subscription = stream.listen(
            (data) {
              R mappedValue;

              try {
                mappedValue = mapper(data);
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
        },
        onPause: ([Future resumeSignal]) => subscription.pause(resumeSignal),
        onResume: () => subscription.resume(),
        onCancel: () => subscription.cancel(),
      );

      return controller.stream.listen(null);
    });
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
