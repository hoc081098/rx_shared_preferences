import 'dart:async';

///
class MapNotNullStreamTransformer<T, R> extends StreamTransformerBase<T, R> {
  final StreamTransformer<T, R> _transformer;

  ///
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

///
extension MapNotNullStreamExtension<T> on Stream<T> {
  ///
  Stream<R> mapNotNull<R>(R Function(T) mapper) =>
      transform(MapNotNullStreamTransformer(mapper));
}
