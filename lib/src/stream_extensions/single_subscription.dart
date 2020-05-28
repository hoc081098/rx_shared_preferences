import 'dart:async';

/// A transformer that converts a broadcast stream into a single-subscription
/// stream.
class SingleSubscriptionTransformer<T> extends StreamTransformerBase<T, T> {
  ///
  const SingleSubscriptionTransformer();

  @override
  Stream<T> bind(Stream<T> stream) {
    StreamSubscription<T> subscription;
    StreamController<T> controller;

    controller = StreamController<T>(
      sync: true,
      onListen: () {
        subscription = stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () => subscription.cancel(),
    );

    return controller.stream;
  }
}

///
extension ToSingleSubscriptionStreamExtension<T> on Stream<T> {
  ///
  Stream<T> toSingleSubscriptionStream() =>
      transform(SingleSubscriptionTransformer<T>());
}
