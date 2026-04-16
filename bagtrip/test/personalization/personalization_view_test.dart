// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/personalization/bloc/personalization_bloc.dart';
import 'package:bagtrip/personalization/view/personalization_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_widget.dart';

class _MockPersonalizationBloc
    extends MockBloc<PersonalizationEvent, PersonalizationState>
    implements PersonalizationBloc {}

void main() {
  late _MockPersonalizationBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoadPersonalization());
    registerFallbackValue(PersonalizationInitial());
  });

  setUp(() {
    mockBloc = _MockPersonalizationBloc();
  });

  Future<void> pump(WidgetTester tester, PersonalizationState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<PersonalizationState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<PersonalizationBloc>.value(
        value: mockBloc,
        child: const PersonalizationView(),
      ),
    );
    await tester.pump();
  }

  PersonalizationLoaded loaded({
    int step = 0,
    Set<String> travelTypes = const {},
    String? travelStyle,
    String? budget,
    String? companions,
    String? travelFrequency,
    String? constraints,
  }) {
    return PersonalizationLoaded(
      step: step,
      userId: 'user-1',
      selectedTravelTypes: travelTypes,
      travelStyle: travelStyle,
      budget: budget,
      companions: companions,
      travelFrequency: travelFrequency,
      constraints: constraints,
    );
  }

  group('PersonalizationView', () {
    testWidgets('renders initial state placeholder', (tester) async {
      await pump(tester, PersonalizationInitial());
      expect(find.byType(PersonalizationView), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await pump(tester, PersonalizationLoading());
      expect(find.byType(PersonalizationView), findsOneWidget);
    });

    testWidgets('renders welcome step (step 0)', (tester) async {
      await pump(tester, loaded(step: 0));
      expect(find.byType(PersonalizationView), findsOneWidget);
    });

    testWidgets('renders companions step (step 1)', (tester) async {
      await pump(tester, loaded(step: 1, companions: 'couple'));
      expect(find.byType(PersonalizationView), findsOneWidget);
    });

    testWidgets('renders budget step (step 2)', (tester) async {
      await pump(tester, loaded(step: 2, budget: 'medium'));
      expect(find.byType(PersonalizationView), findsOneWidget);
    });

    testWidgets('renders travel types step (step 3)', (tester) async {
      await pump(tester, loaded(step: 3, travelTypes: {'beach', 'culture'}));
      expect(find.byType(PersonalizationView), findsOneWidget);
    });

    testWidgets('renders travel frequency step (step 4)', (tester) async {
      await pump(tester, loaded(step: 4, travelFrequency: 'often'));
      expect(find.byType(PersonalizationView), findsOneWidget);
    });

    testWidgets('renders constraints step (step 5)', (tester) async {
      await pump(tester, loaded(step: 5, constraints: 'no nuts'));
      expect(find.byType(PersonalizationView), findsOneWidget);
    });
  });
}
