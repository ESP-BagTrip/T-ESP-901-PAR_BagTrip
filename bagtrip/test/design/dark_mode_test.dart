// SMP327-053 — dark-mode rendering smoke tests.
//
// No existing test pumped widgets under `Brightness.dark` / `AppTheme.dark()`,
// so brightness-aware regressions (SMP327-051) went uncaught. These tests
// mount key components under the dark theme, assert they render without throwing
// and that the brightness-aware AppColors resolvers actually diverge between
// light and dark.
import 'package:bagtrip/components/adaptive/adaptive_button.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_theme.dart';
import 'package:bagtrip/design/widgets/item_status_chip.dart';
import 'package:bagtrip/design/widgets/review/budget_alert_banner.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside a fully-configured MaterialApp running [AppTheme.dark]
/// forced via `themeMode: ThemeMode.dark`.
Widget _darkApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('SMP327-053 — dark mode widget rendering', () {
    testWidgets('AdaptiveButton renders under dark theme', (tester) async {
      await tester.pumpWidget(
        _darkApp(AdaptiveButton(label: 'Go', onPressed: () {})),
      );
      await tester.pump();

      expect(find.text('Go'), findsOneWidget);
      // The enclosing theme must actually be dark.
      final ctx = tester.element(find.text('Go'));
      expect(Theme.of(ctx).brightness, Brightness.dark);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ItemStatusChip renders all kinds under dark theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _darkApp(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ItemStatusChip(kind: ItemStatusChipKind.suggested),
              ItemStatusChip(kind: ItemStatusChipKind.validated),
              ItemStatusChip(kind: ItemStatusChipKind.manual),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ItemStatusChip), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'BudgetAlertBanner (brightness-aware in 051) renders inside a bottom '
      'sheet under dark theme',
      (tester) async {
        const summary = BudgetSummary(
          totalBudget: 100,
          totalSpent: 120,
          alertLevel: 'DANGER',
        );

        await tester.pumpWidget(
          _darkApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const BudgetAlertBanner(summary: summary),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.text('open'));
        await tester.pump(); // start the sheet route
        await tester.pump(const Duration(milliseconds: 400)); // settle anim

        expect(find.byType(BudgetAlertBanner), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('SMP327-051 — brightness-aware resolvers diverge dark vs light', () {
    test('alert banner resolvers return distinct dark variants', () {
      expect(
        AppColors.warningBgOf(Brightness.dark),
        isNot(AppColors.warningBgOf(Brightness.light)),
      );
      expect(
        AppColors.warningTextOf(Brightness.dark),
        isNot(AppColors.warningTextOf(Brightness.light)),
      );
      expect(
        AppColors.warningIconOf(Brightness.dark),
        isNot(AppColors.warningIconOf(Brightness.light)),
      );
      expect(
        AppColors.warningBorderOf(Brightness.dark),
        isNot(AppColors.warningBorderOf(Brightness.light)),
      );
      expect(
        AppColors.dangerBgOf(Brightness.dark),
        isNot(AppColors.dangerBgOf(Brightness.light)),
      );
      expect(
        AppColors.dangerTextOf(Brightness.dark),
        isNot(AppColors.dangerTextOf(Brightness.light)),
      );
    });

    test('error feedback resolvers return distinct dark variants', () {
      expect(
        AppColors.errorBgOf(Brightness.dark),
        isNot(AppColors.errorBgOf(Brightness.light)),
      );
      expect(
        AppColors.errorTextOf(Brightness.dark),
        isNot(AppColors.errorTextOf(Brightness.light)),
      );
    });

    test('review neutral resolvers return distinct dark variants', () {
      expect(
        AppColors.reviewMutedOf(Brightness.dark),
        isNot(AppColors.reviewMutedOf(Brightness.light)),
      );
      expect(
        AppColors.reviewInkOf(Brightness.dark),
        isNot(AppColors.reviewInkOf(Brightness.light)),
      );
      expect(
        AppColors.reviewUncheckedOf(Brightness.dark),
        isNot(AppColors.reviewUncheckedOf(Brightness.light)),
      );
      expect(
        AppColors.reviewDividerOf(Brightness.dark),
        isNot(AppColors.reviewDividerOf(Brightness.light)),
      );
    });

    test('AI chip resolvers return distinct dark variants', () {
      expect(
        AppColors.chipWeatherBackgroundOf(Brightness.dark),
        isNot(AppColors.chipWeatherBackgroundOf(Brightness.light)),
      );
      expect(
        AppColors.chipWeatherForegroundOf(Brightness.dark),
        isNot(AppColors.chipWeatherForegroundOf(Brightness.light)),
      );
      expect(
        AppColors.chipActivityBackgroundOf(Brightness.dark),
        isNot(AppColors.chipActivityBackgroundOf(Brightness.light)),
      );
      expect(
        AppColors.chipActivityForegroundOf(Brightness.dark),
        isNot(AppColors.chipActivityForegroundOf(Brightness.light)),
      );
    });

    test('budget ring resolvers return distinct dark variants', () {
      expect(
        AppColors.budgetTransportOf(Brightness.dark),
        isNot(AppColors.budgetTransportOf(Brightness.light)),
      );
      expect(
        AppColors.budgetDefaultOf(Brightness.dark),
        isNot(AppColors.budgetDefaultOf(Brightness.light)),
      );
    });

    test('light brightness still returns the original light constants', () {
      expect(AppColors.warningBgOf(Brightness.light), AppColors.warningBg);
      expect(AppColors.reviewInkOf(Brightness.light), AppColors.reviewInk);
      expect(
        AppColors.chipWeatherForegroundOf(Brightness.light),
        AppColors.chipWeatherForeground,
      );
    });
  });
}
