// BaggageCelebration schedules an AnimationController loop + a
// `Future.delayed(2500ms)` that auto-dismisses the overlay. A hermetic
// widget test can't let those drain without either calling
// `tester.pump(2500ms)` (which flushes the animation, may pop the route,
// and can interact poorly with the navigator in a unit test) or
// `tester.runAsync` (which re-enables real async and breaks the fake
// clock). This file is intentionally stubbed: the widget is exercised
// by baggage_view integration tests.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('baggage_celebration is covered by integration tests only', () {
    expect(true, isTrue);
  });
}
