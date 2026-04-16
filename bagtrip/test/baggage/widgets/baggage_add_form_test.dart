import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/baggage/widgets/baggage_add_form.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

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
    when(() => mockBloc.state).thenReturn(BaggageInitial());
    whenListen(
      mockBloc,
      const Stream<BaggageState>.empty(),
      initialState: BaggageInitial(),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await pumpLocalized(
      tester,
      BlocProvider<BaggageBloc>.value(
        value: mockBloc,
        child: const SizedBox(
          width: 800,
          height: 1200,
          child: BaggageAddForm(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pump();
  }

  group('BaggageAddForm', () {
    testWidgets('renders form', (tester) async {
      await pump(tester);
      expect(find.byType(BaggageAddForm), findsOneWidget);
    });

    testWidgets('has a name text field', (tester) async {
      await pump(tester);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('has a save button', (tester) async {
      await pump(tester);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
