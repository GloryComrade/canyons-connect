import 'dart:async';

/// A tiny value-holding broadcast store. New subscribers immediately receive
/// the current value (replay-latest), then every subsequent update — mirroring
/// how Supabase Realtime streams behave for the UI.
class ReactiveStore<T> {
  ReactiveStore(this._value);

  T _value;
  final _controller = StreamController<T>.broadcast();

  T get value => _value;

  set value(T next) {
    _value = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  /// Mutate in place then notify.
  void update(T Function(T current) mutator) => value = mutator(_value);

  Stream<T> get stream async* {
    yield _value;
    yield* _controller.stream;
  }

  Future<void> dispose() => _controller.close();
}
