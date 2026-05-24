import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/baggage/widgets/baggage_edit_form.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/test_fixtures.dart';

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

  Future<void> pump(
    WidgetTester tester, {
    String? category,
    int? quantity,
  }) async {
    await pumpLocalized(
      tester,
      BlocProvider<BaggageBloc>.value(
        value: mockBloc,
        child: SizedBox(
          width: 800,
          height: 1200,
          child: BaggageEditForm(
            tripId: 'trip-1',
            item: makeBaggageItem(category: category, quantity: quantity),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('BaggageEditForm', () {
    testWidgets('renders form with default item', (tester) async {
      await pump(tester);
      expect(find.byType(BaggageEditForm), findsOneWidget);
    });

    testWidgets('renders with item category and quantity', (tester) async {
      await pump(tester, category: 'CLOTHING', quantity: 3);
      expect(find.byType(BaggageEditForm), findsOneWidget);
    });

    testWidgets('has save button and text field', (tester) async {
      await pump(tester, category: 'OTHER', quantity: 1);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
