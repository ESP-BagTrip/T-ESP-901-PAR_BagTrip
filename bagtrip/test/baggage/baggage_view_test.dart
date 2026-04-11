import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/baggage/view/baggage_view.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bloc_test/bloc_test.dart';
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

  Future<void> pump(WidgetTester tester, BaggageState seed) async {
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
        child: const BaggageView(tripId: 'trip-1'),
      ),
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
}
