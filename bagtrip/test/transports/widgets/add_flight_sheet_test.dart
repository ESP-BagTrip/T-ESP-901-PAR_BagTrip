import 'package:bagtrip/transports/bloc/transport_bloc.dart';
import 'package:bagtrip/transports/widgets/add_flight_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

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
    when(() => mockBloc.state).thenReturn(TransportInitial());
    whenListen(
      mockBloc,
      const Stream<TransportState>.empty(),
      initialState: TransportInitial(),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await pumpLocalized(
      tester,
      BlocProvider<TransportBloc>.value(
        value: mockBloc,
        child: Builder(
          builder: (context) => SizedBox(
            width: 800,
            height: 1200,
            child: AddFlightSheet(tripId: 'trip-1', parentContext: context),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('AddFlightSheet', () {
    testWidgets('renders with options', (tester) async {
      await pump(tester);
      expect(find.byType(AddFlightSheet), findsOneWidget);
    });

    testWidgets('renders two option tiles', (tester) async {
      await pump(tester);
      expect(find.byType(InkWell), findsNWidgets(2));
    });
  });
}
