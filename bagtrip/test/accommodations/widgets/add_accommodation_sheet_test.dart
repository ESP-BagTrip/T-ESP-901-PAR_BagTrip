// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/widgets/add_accommodation_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

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
    when(() => mockBloc.state).thenReturn(AccommodationInitial());
    whenListen(
      mockBloc,
      const Stream<AccommodationState>.empty(),
      initialState: AccommodationInitial(),
    );
  });

  Future<void> pump(
    WidgetTester tester, {
    DateTime? startDate,
    DateTime? endDate,
    String? destinationIata,
  }) async {
    await pumpLocalized(
      tester,
      BlocProvider<AccommodationBloc>.value(
        value: mockBloc,
        child: SizedBox(
          width: 800,
          height: 1200,
          child: AddAccommodationSheet(
            tripId: 'trip-1',
            tripStartDate: startDate,
            tripEndDate: endDate,
            destinationIata: destinationIata,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('AddAccommodationSheet', () {
    testWidgets('renders with no dates', (tester) async {
      await pump(tester);
      expect(find.byType(AddAccommodationSheet), findsOneWidget);
    });

    testWidgets('renders with trip dates and destination', (tester) async {
      await pump(
        tester,
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 7),
        destinationIata: 'PAR',
      );
      expect(find.byType(AddAccommodationSheet), findsOneWidget);
    });

    testWidgets('renders InkWell options for manual and search', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byType(InkWell), findsNWidgets(2));
    });
  });
}
