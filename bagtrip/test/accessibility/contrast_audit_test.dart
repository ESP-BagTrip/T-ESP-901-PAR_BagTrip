import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'a11y_test_helpers.dart';

void main() {
  group('AX4 — Contrast audit', () {
    test('AppColors.textSecondary has >= 4.5:1 contrast on white', () {
      final ratio = contrastRatio(AppColors.textSecondary, Colors.white);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'textSecondary ($ratio) must be >= 4.5:1 on white',
      );
    });

    test('AppColors.textTertiary has >= 4.5:1 contrast on white', () {
      final ratio = contrastRatio(AppColors.textTertiary, Colors.white);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'textTertiary ($ratio) must be >= 4.5:1 on white',
      );
    });

    test('AppColors.textDisabled has >= 4.5:1 contrast on white', () {
      final ratio = contrastRatio(AppColors.textDisabled, Colors.white);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'textDisabled ($ratio) must be >= 4.5:1 on white',
      );
    });

    test(
      'AppColors.textSecondaryDark has >= 4.5:1 contrast on primaryTrueDark',
      () {
        final ratio = contrastRatio(
          AppColors.textSecondaryDark,
          ColorName.primaryTrueDark,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              'textSecondaryDark ($ratio) must be >= 4.5:1 on primaryTrueDark',
        );
      },
    );

    test(
      'AppColors.warningText has >= 3:1 contrast on warningBg (large text AA)',
      () {
        // warningText (#E65100) is used on warningBg (#FFF3E0), not white.
        // Large text (>= 18pt bold) requires 3:1 per WCAG AA.
        final ratio = contrastRatio(AppColors.warningText, AppColors.warningBg);
        expect(
          ratio,
          greaterThanOrEqualTo(3.0),
          reason:
              'warningText ($ratio) must be >= 3:1 on warningBg (large text AA)',
        );
      },
    );

    test('contrastRatio helper returns 21:1 for black on white', () {
      final ratio = contrastRatio(Colors.black, Colors.white);
      expect(ratio, closeTo(21.0, 0.1));
    });

    test('contrastRatio helper returns 1:1 for same color', () {
      final ratio = contrastRatio(Colors.red, Colors.red);
      expect(ratio, closeTo(1.0, 0.01));
    });
  });
}
