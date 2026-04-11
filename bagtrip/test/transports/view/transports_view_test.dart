import 'package:bagtrip/transports/bloc/transport_bloc.dart';
import 'package:bagtrip/transports/view/transports_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/test_fixtures.dart';

class _MockTransportBloc extends MockBloc<TransportEvent, TransportState>
    implements TransportBloc {}

class _FakeTransportEvent extends Fake implements TransportEvent {}

class _FakeTransportState extends Fake implements TransportState {}

void main() {
  late _MockTransportBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(_FakeTransportEvent());
    registerFallbackValue(_FakeTransportState());
  });

  setUp(() {
    mockBloc = _MockTransportBloc();
  });

  Future<void> pump(WidgetTester tester, TransportState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<TransportState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<TransportBloc>.value(
        value: mockBloc,
        child: const TransportsView(tripId: 'trip-1'),
      ),
    );
    await tester.pump();
  }

  group('TransportsView', () {
    testWidgets('renders loading state', (tester) async {
      await pump(tester, TransportLoading());
      expect(find.byType(TransportsView), findsOneWidget);
    });

    testWidgets('renders empty loaded state', (tester) async {
      await pump(
        tester,
        TransportsLoaded(
          transports: const [],
          mainFlights: const [],
          internalFlights: const [],
        ),
      );
      expect(find.byType(TransportsView), findsOneWidget);
    });

    testWidgets('renders populated loaded state with main and internal', (
      tester,
    ) async {
      final main = makeManualFlight();
      final internal = makeManualFlight(id: 'flight-2');
      await pump(
        tester,
        TransportsLoaded(
          transports: [main, internal],
          mainFlights: [main],
          internalFlights: [internal],
        ),
      );
      expect(find.byType(TransportsView), findsOneWidget);
    });

    testWidgets('renders viewer role variant', (tester) async {
      when(() => mockBloc.state).thenReturn(
        TransportsLoaded(
          transports: [makeManualFlight()],
          mainFlights: [makeManualFlight()],
          internalFlights: const [],
        ),
      );
      whenListen(
        mockBloc,
        const Stream<TransportState>.empty(),
        initialState: TransportsLoaded(
          transports: [makeManualFlight()],
          mainFlights: [makeManualFlight()],
          internalFlights: const [],
        ),
      );
      await pumpLocalized(
        tester,
        BlocProvider<TransportBloc>.value(
          value: mockBloc,
          child: const TransportsView(tripId: 'trip-1', role: 'VIEWER'),
        ),
      );
      await tester.pump();
      expect(find.byType(TransportsView), findsOneWidget);
    });
  });
}
