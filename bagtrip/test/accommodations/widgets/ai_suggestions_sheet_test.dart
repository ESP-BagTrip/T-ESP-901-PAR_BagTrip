import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/widgets/ai_suggestions_sheet.dart';
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
    WidgetTester tester,
    List<Map<String, dynamic>> suggestions,
  ) async {
    await pumpLocalized(
      tester,
      BlocProvider<AccommodationBloc>.value(
        value: mockBloc,
        child: SizedBox(
          width: 800,
          height: 1200,
          child: AiSuggestionsSheet(tripId: 'trip-1', suggestions: suggestions),
        ),
      ),
    );
    await tester.pump();
  }

  group('AiSuggestionsSheet', () {
    testWidgets('renders with empty suggestions', (tester) async {
      await pump(tester, []);
      expect(find.byType(AiSuggestionsSheet), findsOneWidget);
    });

    testWidgets('renders with populated suggestions', (tester) async {
      await pump(tester, [
        {
          'type': 'HOTEL',
          'name': 'Hotel X',
          'neighborhood': 'Center',
          'priceRange': '100-200',
          'currency': 'EUR',
          'reason': 'Great location',
        },
        {
          'type': 'AIRBNB',
          'name': 'Cozy Flat',
          'neighborhood': 'Montmartre',
          'priceRange': '50-80',
          'currency': 'EUR',
          'reason': 'Affordable',
        },
      ]);
      expect(find.byType(AiSuggestionsSheet), findsOneWidget);
    });

    testWidgets('renders suggestion with missing optional fields', (
      tester,
    ) async {
      await pump(tester, [
        {'type': 'CAMPING', 'name': 'Camping Site'},
      ]);
      expect(find.byType(AiSuggestionsSheet), findsOneWidget);
    });
  });
}
