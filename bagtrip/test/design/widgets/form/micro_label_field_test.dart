import 'package:bagtrip/design/widgets/form/micro_label_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders micro-label and responds to readOnly tap', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MicroLabelField(
            label: 'Départ',
            readOnly: true,
            displayValue: '--/-- --:--',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('DÉPART'), findsOneWidget);
    expect(find.text('--/-- --:--'), findsOneWidget);

    await tester.tap(find.text('--/-- --:--'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('renders editable field with controller', (tester) async {
    final controller = TextEditingController(text: 'CDG');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MicroLabelField(
            label: 'Départ',
            controller: controller,
            hint: 'XXX',
          ),
        ),
      ),
    );

    expect(find.text('DÉPART'), findsOneWidget);
    expect(find.text('CDG'), findsOneWidget);
  });
}
