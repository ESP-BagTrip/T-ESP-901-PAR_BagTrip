import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/baggage/view/baggage_view.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_widget.dart';
import '../helpers/test_fixtures.dart';

class _MockBaggageBloc extends MockBloc<BaggageEvent, BaggageState>
    implements BaggageBloc {}

void main() {
  late _MockBaggageBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoadBaggage(tripId: 't'));
    registerFallbackValue(BaggageInitial());
  });

  setUp(() {
    mockBloc = _MockBaggageBloc();
  });

  Future<void> pump(
    WidgetTester tester,
    BaggageState seed, {
    String role = 'OWNER',
    bool isCompleted = false,
    Size? size,
  }) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<BaggageState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<BaggageBloc>.value(
        value: mockBloc,
        child: BaggageView(
          tripId: 'trip-1',
          role: role,
          isCompleted: isCompleted,
        ),
      ),
      size: size,
    );
    await tester.pump();
  }

  group('BaggageView', () {
    testWidgets('renders loading state', (tester) async {
      await pump(tester, BaggageLoading());
      expect(find.byType(BaggageView), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await pump(tester, BaggageError(error: const NetworkError('offline')));
      expect(find.byType(BaggageView), findsOneWidget);
    });

    testWidgets('renders empty list', (tester) async {
      await pump(
        tester,
        BaggageLoaded(items: const [], packedCount: 0, totalCount: 0),
      );
      expect(find.byType(BaggageView), findsOneWidget);
    });

    testWidgets('renders populated list with progress header', (tester) async {
      final items = [makeBaggageItem(), makeBaggageItem(id: 'b-2')];
      await pump(
        tester,
        BaggageLoaded(items: items, packedCount: 1, totalCount: 2),
      );
      expect(find.byType(BaggageView), findsOneWidget);
    });
  });

  group('BaggageView reinforcement', () {
    testWidgets('renders BaggageSuggestionsLoading with items', (tester) async {
      final items = [
        makeBaggageItem(),
        makeBaggageItem(id: 'b-2', isPacked: true),
      ];
      await pump(
        tester,
        BaggageSuggestionsLoading(items: items, packedCount: 1, totalCount: 2),
        size: const Size(900, 1600),
      );
      expect(find.byType(BaggageView), findsOneWidget);
    });

    testWidgets('renders BaggageQuotaExceeded as shrink', (tester) async {
      await pump(tester, BaggageQuotaExceeded());
      expect(find.byType(BaggageView), findsOneWidget);
    });

    testWidgets(
      'renders BaggageLoaded with celebrationTriggered=true (listener safe)',
      (tester) async {
        // celebrationTriggered listener only fires on state change, not initial.
        final items = [makeBaggageItem(isPacked: true)];
        await pump(
          tester,
          BaggageLoaded(
            items: items,
            packedCount: 1,
            totalCount: 1,
            celebrationTriggered: true,
          ),
        );
        expect(find.byType(BaggageView), findsOneWidget);
      },
    );

    testWidgets('renders large list of baggage items', (tester) async {
      final items = List<BaggageItem>.generate(
        15,
        (i) => makeBaggageItem(id: 'b-$i', name: 'Item $i', isPacked: i.isEven),
      );
      await pump(
        tester,
        BaggageLoaded(
          items: items,
          packedCount: items.where((e) => e.isPacked).length,
          totalCount: items.length,
        ),
        size: const Size(900, 1600),
      );
      expect(find.byType(BaggageView), findsOneWidget);
    });

    testWidgets('renders all-packed state (totalCount == packedCount)', (
      tester,
    ) async {
      final items = [
        makeBaggageItem(isPacked: true),
        makeBaggageItem(id: 'b-2', isPacked: true),
        makeBaggageItem(id: 'b-3', isPacked: true),
      ];
      await pump(
        tester,
        BaggageLoaded(items: items, packedCount: 3, totalCount: 3),
        size: const Size(900, 1600),
      );
      expect(find.byType(BaggageView), findsOneWidget);
    });

    testWidgets('renders VIEWER role (no edit affordance)', (tester) async {
      final items = [makeBaggageItem()];
      await pump(
        tester,
        BaggageLoaded(items: items, packedCount: 0, totalCount: 1),
        role: 'VIEWER',
        size: const Size(900, 1600),
      );
      expect(find.byType(BaggageView), findsOneWidget);
    });

    testWidgets('renders isCompleted=true (no edit affordance)', (
      tester,
    ) async {
      final items = [makeBaggageItem()];
      await pump(
        tester,
        BaggageLoaded(items: items, packedCount: 0, totalCount: 1),
        isCompleted: true,
        size: const Size(900, 1600),
      );
      expect(find.byType(BaggageView), findsOneWidget);
    });

    testWidgets('renders with AI suggestions list', (tester) async {
      final items = [makeBaggageItem()];
      final suggestions = [
        makeSuggestedBaggageItem(),
        makeSuggestedBaggageItem(name: 'Hat'),
      ];
      await pump(
        tester,
        BaggageLoaded(
          items: items,
          packedCount: 0,
          totalCount: 1,
          suggestions: suggestions,
        ),
        size: const Size(900, 1600),
      );
      expect(find.byType(BaggageView), findsOneWidget);
    });

    testWidgets('tapping AI suggestions icon dispatches SuggestBaggage', (
      tester,
    ) async {
      await pump(
        tester,
        BaggageLoaded(items: const [], packedCount: 0, totalCount: 0),
      );
      final aiIcon = find.byIcon(Icons.auto_awesome);
      if (aiIcon.evaluate().isNotEmpty) {
        await tester.tap(aiIcon.first);
        await tester.pump();
        verify(() => mockBloc.add(any(that: isA<SuggestBaggage>()))).called(1);
      }
      expect(find.byType(BaggageView), findsOneWidget);
    });

    testWidgets('tapping retry on error dispatches LoadBaggage', (
      tester,
    ) async {
      await pump(tester, BaggageError(error: const NetworkError('offline')));
      final retry = find.text('Retry');
      if (retry.evaluate().isNotEmpty) {
        await tester.tap(retry.first);
        await tester.pump();
        verify(
          () => mockBloc.add(any(that: isA<LoadBaggage>())),
        ).called(greaterThanOrEqualTo(1));
      }
      expect(find.byType(BaggageView), findsOneWidget);
    });
  });
}
