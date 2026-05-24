import 'package:bagtrip/design/app_animations.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAnimations', () {
    test('springCurve is easeOutBack', () {
      expect(AppAnimations.springCurve, Curves.easeOutBack);
    });

    test('standardCurve is easeOutCubic', () {
      expect(AppAnimations.standardCurve, Curves.easeOutCubic);
    });

    test('staggerDelay is 80ms', () {
      expect(AppAnimations.staggerDelay, const Duration(milliseconds: 80));
    });

    test('cardTransition is 350ms', () {
      expect(AppAnimations.cardTransition, const Duration(milliseconds: 350));
    });

    test('microInteraction is 200ms', () {
      expect(AppAnimations.microInteraction, const Duration(milliseconds: 200));
    });

    test('wizardTransition is 300ms', () {
      expect(AppAnimations.wizardTransition, const Duration(milliseconds: 300));
    });

    test('fadeIn is 400ms', () {
      expect(AppAnimations.fadeIn, const Duration(milliseconds: 400));
    });

    test('pressFeedback is 150ms', () {
      expect(AppAnimations.pressFeedback, const Duration(milliseconds: 150));
    });
  });
}
