import 'dart:async';

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/cubit/quick_expense_cubit.dart';
import 'package:bagtrip/home/widgets/quick_expense_sheet.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/repositories/budget_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late MockBudgetRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRepo = MockBudgetRepository();
  });

  Widget buildApp({QuickExpenseCubit? cubit}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider(
                  create: (_) => cubit ?? QuickExpenseCubit(repo: mockRepo),
                  child: const QuickExpenseSheet(tripId: 'trip-1'),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester, {
    QuickExpenseCubit? cubit,
  }) async {
    await tester.pumpWidget(buildApp(cubit: cubit));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('QuickExpenseSheet', () {
    testWidgets('displays title', (tester) async {
      await openSheet(tester);
      expect(find.text('Quick expense'), findsOneWidget);
    });

    testWidgets('displays amount field with euro icon', (tester) async {
      await openSheet(tester);
      expect(find.byIcon(Icons.euro), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
    });

    testWidgets('displays 4 category chips', (tester) async {
      await openSheet(tester);
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('Food category selected by default', (tester) async {
      await openSheet(tester);
      final foodChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Food'),
      );
      expect(foodChip.selected, isTrue);
    });

    testWidgets('can select different category', (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();

      final transportChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Transport'),
      );
      expect(transportChip.selected, isTrue);
    });

    testWidgets('displays note field', (tester) async {
      await openSheet(tester);
      expect(find.text('Note (optional)'), findsOneWidget);
    });

    testWidgets('displays save button', (tester) async {
      await openSheet(tester);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('validates empty amount', (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Amount is required'), findsOneWidget);
    });

    testWidgets('validates invalid amount (0)', (tester) async {
      await openSheet(tester);
      await tester.enterText(find.byType(TextFormField).first, '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid amount'), findsOneWidget);
    });

    testWidgets('calls saveExpense on valid submission', (tester) async {
      when(() => mockRepo.createBudgetItem(any(), any())).thenAnswer(
        (_) async => Success(
          BudgetItem(
            id: '1',
            tripId: 'trip-1',
            label: 'FOOD',
            amount: 25.0,
            category: BudgetCategory.food,
            date: DateTime.now(),
            isPlanned: false,
          ),
        ),
      );

      await openSheet(tester);
      await tester.enterText(find.byType(TextFormField).first, '25');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.createBudgetItem('trip-1', any())).called(1);
    });

    testWidgets('shows spinner while saving', (tester) async {
      final completer = Completer<Result<BudgetItem>>();
      when(
        () => mockRepo.createBudgetItem(any(), any()),
      ).thenAnswer((_) => completer.future);

      await openSheet(tester);
      await tester.enterText(find.byType(TextFormField).first, '10');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future to avoid pending timers
      completer.complete(const Failure(UnknownError('timeout')));
      await tester.pumpAndSettle();
    });

    testWidgets('has handle bar decoration', (tester) async {
      await openSheet(tester);

      // Verify the 40x4 handle bar container exists
      final handleFinder = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == 40 &&
            w.constraints?.maxHeight == 4,
      );
      expect(handleFinder, findsOneWidget);
    });
  });
}
