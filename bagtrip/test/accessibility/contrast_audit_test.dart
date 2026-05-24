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

    // ── SMP327-045: dark surface audit ──────────────────────────────────
    // Dark theme surfaces (app_theme.dart dark()):
    //   scaffold      = primaryTrueDark  (#0E2135)
    //   colorScheme   = primaryDark      (#1F4772)  (cards / containers)
    //   surfaceDark   = #2A2F3D                       (alt cards)
    //   input bg      = inputBackgroundDark (#353B4A)
    // Primary text on dark = AppColors.surface (white).
    // Titles on dark = ColorName.secondary (#35A8B5), rendered bold/large.

    test('primary text (white) >= 4.5:1 on primaryTrueDark (scaffold)', () {
      final ratio = contrastRatio(AppColors.surface, ColorName.primaryTrueDark);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'white text ($ratio) must be >= 4.5:1 on primaryTrueDark',
      );
    });

    test('primary text (white) >= 4.5:1 on surfaceDark (card)', () {
      final ratio = contrastRatio(AppColors.surface, ColorName.surfaceDark);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'white text ($ratio) must be >= 4.5:1 on surfaceDark',
      );
    });

    test(
      'primary text (white) >= 4.5:1 on primaryDark (colorScheme.surface)',
      () {
        final ratio = contrastRatio(AppColors.surface, ColorName.primaryDark);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'white text ($ratio) must be >= 4.5:1 on primaryDark',
        );
      },
    );

    test('title color (secondary) >= 3:1 on primaryTrueDark (large/bold)', () {
      final ratio = contrastRatio(
        ColorName.secondary,
        ColorName.primaryTrueDark,
      );
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason:
            'title secondary ($ratio) must be >= 3:1 on primaryTrueDark (large)',
      );
    });

    test('title color (secondary) >= 3:1 on surfaceDark (large/bold)', () {
      final ratio = contrastRatio(ColorName.secondary, ColorName.surfaceDark);
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason:
            'title secondary ($ratio) must be >= 3:1 on surfaceDark (large)',
      );
    });

    // Title secondary on primaryDark = ~3.37:1. PASSES the 3:1 large-text/UI
    // threshold but is BELOW the 4.5:1 normal-text threshold — only safe for
    // bold/large titles (which is how it is used in app_theme.dart titleLarge).
    test('title color (secondary) >= 3:1 on primaryDark (large/bold only)', () {
      final ratio = contrastRatio(ColorName.secondary, ColorName.primaryDark);
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason:
            'title secondary ($ratio) must be >= 3:1 on primaryDark (large)',
      );
      // Document that it does NOT meet normal-text AA.
      expect(
        ratio,
        lessThan(4.5),
        reason: 'secondary on primaryDark stays below 4.5:1 — large text only',
      );
    });

    test('textSecondaryDark >= 4.5:1 on surfaceDark (card)', () {
      final ratio = contrastRatio(
        AppColors.textSecondaryDark,
        ColorName.surfaceDark,
      );
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'textSecondaryDark ($ratio) must be >= 4.5:1 on surfaceDark',
      );
    });

    test('textSecondaryDark >= 4.5:1 on primaryDark (card)', () {
      final ratio = contrastRatio(
        AppColors.textSecondaryDark,
        ColorName.primaryDark,
      );
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'textSecondaryDark ($ratio) must be >= 4.5:1 on primaryDark',
      );
    });

    test('dark hint (white @ 0.7) >= 4.5:1 on inputBackgroundDark', () {
      // app_theme.dart dark() hintStyle = ColorName.surface @ alpha 0.7.
      final hint = Color.alphaBlend(
        ColorName.surface.withValues(alpha: 0.7),
        ColorName.inputBackgroundDark,
      );
      final ratio = contrastRatio(hint, ColorName.inputBackgroundDark);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'dark hint ($ratio) must be >= 4.5:1 on inputBackgroundDark',
      );
    });

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
