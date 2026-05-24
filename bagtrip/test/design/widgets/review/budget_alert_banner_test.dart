import 'package:bagtrip/design/widgets/review/budget_alert_banner.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BudgetSummary summary({
    required double totalBudget,
    required double totalSpent,
    String? alertLevel,
  }) {
    return BudgetSummary(
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      remaining: totalBudget - totalSpent,
      percentConsumed: totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0,
      alertLevel: alertLevel,
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  testWidgets('renders nothing when alertLevel is null', (tester) async {
    await tester.pumpWidget(
      wrap(
        BudgetAlertBanner(summary: summary(totalBudget: 1000, totalSpent: 100)),
      ),
    );

    expect(find.byType(Container), findsNothing);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  testWidgets('renders WARNING variant with percent message', (tester) async {
    await tester.pumpWidget(
      wrap(
        BudgetAlertBanner(
          summary: summary(
            totalBudget: 1000,
            totalSpent: 850,
            alertLevel: 'WARNING',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.textContaining('85%'), findsOneWidget);
  });

  testWidgets('renders DANGER variant with over-budget amount', (tester) async {
    await tester.pumpWidget(
      wrap(
        BudgetAlertBanner(
          summary: summary(
            totalBudget: 1000,
            totalSpent: 1250,
            alertLevel: 'DANGER',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.textContaining('250'), findsOneWidget);
  });
}
