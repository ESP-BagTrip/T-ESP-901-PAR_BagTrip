import 'dart:async';

class AuthEventBus {
  static final _controller = StreamController<void>.broadcast();
  static Stream<void> get onUnauthenticated => _controller.stream;
  static void fireUnauthenticated() => _controller.add(null);
}
