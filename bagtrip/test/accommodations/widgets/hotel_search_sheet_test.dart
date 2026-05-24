import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/widgets/hotel_search_sheet.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccommodationBloc extends Mock implements AccommodationBloc {
  @override
  Future<void> close() async {}
}

class FakeAccommodationEvent extends Fake implements AccommodationEvent {}

void main() {
  late MockAccommodationBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(FakeAccommodationEvent());
  });

  setUp(() {
    mockBloc = MockAccommodationBloc();
    when(() => mockBloc.state).thenReturn(AccommodationInitial());
    when(
      () => mockBloc.stream,
    ).thenAnswer((_) => const Stream<AccommodationState>.empty());
  });

  Widget buildApp({String? initialCityCode}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
                builder: (_) => BlocProvider<AccommodationBloc>.value(
                  value: mockBloc,
                  child: HotelSearchSheet(
                    tripId: 'trip-1',
                    initialCityCode: initialCityCode,
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester, {String? initialCityCode}) async {
    await tester.pumpWidget(buildApp(initialCityCode: initialCityCode));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('HotelSearchSheet', () {
    testWidgets('displays search title and input', (tester) async {
      await openSheet(tester);
      expect(find.text('Search a hotel'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('auto-search triggered when initialCityCode provided', (
      tester,
    ) async {
      await openSheet(tester, initialCityCode: 'PAR');

      verify(() => mockBloc.add(any(that: isA<SearchHotels>()))).called(1);
    });

    testWidgets('pre-fills search field with initialCityCode', (tester) async {
      await openSheet(tester, initialCityCode: 'LON');

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'LON');
    });

    testWidgets('hotel card displays address info', (tester) async {
      when(() => mockBloc.state).thenReturn(
        HotelSearchLoaded(
          hotels: [
            {
              'name': 'Grand Hotel',
              'hotelId': 'H123',
              'address': {'cityName': 'Paris', 'countryCode': 'FR'},
            },
          ],
        ),
      );
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          HotelSearchLoaded(
            hotels: [
              {
                'name': 'Grand Hotel',
                'hotelId': 'H123',
                'address': {'cityName': 'Paris', 'countryCode': 'FR'},
              },
            ],
          ),
        ),
      );

      await openSheet(tester);

      expect(find.text('Grand Hotel'), findsOneWidget);
      expect(find.text('Paris, FR'), findsOneWidget);
    });

    testWidgets('shows no results message when empty', (tester) async {
      when(() => mockBloc.state).thenReturn(HotelSearchLoaded(hotels: []));
      when(
        () => mockBloc.stream,
      ).thenAnswer((_) => Stream.value(HotelSearchLoaded(hotels: [])));

      await openSheet(tester);

      expect(find.text('No hotels found'), findsOneWidget);
    });

    testWidgets('select button is present on hotel card', (tester) async {
      when(() => mockBloc.state).thenReturn(
        HotelSearchLoaded(
          hotels: [
            {
              'name': 'Test Hotel',
              'hotelId': 'H1',
              'address': {'cityName': 'London', 'countryCode': 'GB'},
            },
          ],
        ),
      );
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          HotelSearchLoaded(
            hotels: [
              {
                'name': 'Test Hotel',
                'hotelId': 'H1',
                'address': {'cityName': 'London', 'countryCode': 'GB'},
              },
            ],
          ),
        ),
      );

      await openSheet(tester);

      expect(find.text('Select'), findsOneWidget);
    });
  });
}
