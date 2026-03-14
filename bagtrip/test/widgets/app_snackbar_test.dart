import 'package:bagtrip/components/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSnackBar', () {
    Widget buildSubject({
      required String buttonLabel,
      required String message,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppSnackBar.showError(context, message: message),
              child: Text(buttonLabel),
            ),
          ),
        ),
      );
    }

    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    AppSnackBar.showError(context, message: 'Test error'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Test error'), findsOneWidget);

      // Advance past the 4s auto-dismiss + animation duration to clear pending timers
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('removes previous snackbar when showing a new one', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        AppSnackBar.showError(context, message: 'First error'),
                    child: const Text('ShowFirst'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        AppSnackBar.showError(context, message: 'Second error'),
                    child: const Text('ShowSecond'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Show the first snackbar
      await tester.tap(find.text('ShowFirst'));
      await tester.pump();
      expect(find.text('First error'), findsOneWidget);

      // Show the second snackbar — the first should be removed
      await tester.tap(find.text('ShowSecond'));
      await tester.pump();

      expect(find.text('Second error'), findsOneWidget);
      expect(find.text('First error'), findsNothing);

      // Advance past the 4s auto-dismiss + animation to clear pending timers
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('displays the exact message text passed to showError', (
      tester,
    ) async {
      const msg = 'Something went very wrong!';
      await tester.pumpWidget(
        buildSubject(buttonLabel: 'Trigger', message: msg),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(find.text(msg), findsOneWidget);

      // Advance past the 4s auto-dismiss + animation to clear pending timers
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
