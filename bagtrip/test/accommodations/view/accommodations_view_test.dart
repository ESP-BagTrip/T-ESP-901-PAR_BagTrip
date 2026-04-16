import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/view/accommodations_view.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/test_fixtures.dart';

class _MockAccommodationBloc
    extends MockBloc<AccommodationEvent, AccommodationState>
    implements AccommodationBloc {}

class _FakeAccommodationEvent extends Fake implements AccommodationEvent {}

class _FakeAccommodationState extends Fake implements AccommodationState {}

void main() {
  late _MockAccommodationBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(_FakeAccommodationEvent());
    registerFallbackValue(_FakeAccommodationState());
  });

  setUp(() {
    mockBloc = _MockAccommodationBloc();
  });

  Future<void> pump(WidgetTester tester, AccommodationState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<AccommodationState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<AccommodationBloc>.value(
        value: mockBloc,
        child: const AccommodationsView(tripId: 'trip-1'),
      ),
    );
    await tester.pump();
  }

  group('AccommodationsView', () {
    testWidgets('renders loading state', (tester) async {
      await pump(tester, AccommodationLoading());
      expect(find.byType(AccommodationsView), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await pump(
        tester,
        AccommodationError(error: const NetworkError('offline')),
      );
      expect(find.byType(AccommodationsView), findsOneWidget);
    });

    testWidgets('renders empty loaded state', (tester) async {
      await pump(tester, AccommodationsLoaded(accommodations: const []));
      expect(find.byType(AccommodationsView), findsOneWidget);
    });

    testWidgets('renders populated loaded state', (tester) async {
      await pump(
        tester,
        AccommodationsLoaded(
          accommodations: [
            makeAccommodation(),
            makeAccommodation(id: 'acc-2', name: 'Hotel Two'),
          ],
        ),
      );
      expect(find.byType(AccommodationsView), findsOneWidget);
    });
  });
}
