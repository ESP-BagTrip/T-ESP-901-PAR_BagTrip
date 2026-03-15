import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/snack_bar_scope.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSnackBar', () {
    Widget buildApp({required Widget child}) {
      return MaterialApp(
        home: SnackBarScope(
          child: Scaffold(body: Builder(builder: (context) => child)),
        ),
      );
    }

    Widget buildSubject({
      required String buttonLabel,
      required String message,
    }) {
      return buildApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AppSnackBar.showError(context, message: message),
            child: Text(buttonLabel),
          ),
        ),
      );
    }

    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AppSnackBar.showError(context, message: 'Test error'),
              child: const Text('Show'),
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
        buildApp(
          child: Builder(
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

    testWidgets('auto-dismisses after 4 seconds', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AppSnackBar.showError(context, message: 'Dismiss me'),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      expect(find.text('Dismiss me'), findsOneWidget);

      // Still visible before 4s
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Dismiss me'), findsOneWidget);

      // After 4s + reverse animation (400ms) it should be gone
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Dismiss me'), findsNothing);
    });

    testWidgets('showSuccess and showInfo work via the facade', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () =>
                      AppSnackBar.showSuccess(context, message: 'Success msg'),
                  child: const Text('Success'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      AppSnackBar.showInfo(context, message: 'Info msg'),
                  child: const Text('Info'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Success'));
      await tester.pump();
      expect(find.text('Success msg'), findsOneWidget);

      // Replace with info
      await tester.tap(find.text('Info'));
      await tester.pump();
      expect(find.text('Info msg'), findsOneWidget);
      expect(find.text('Success msg'), findsNothing);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('types use the correct colors', (tester) async {
      Color? findSnackBarColor(WidgetTester tester) {
        final containers = tester.widgetList<Container>(find.byType(Container));
        for (final c in containers) {
          if (c.decoration is BoxDecoration) {
            final d = c.decoration! as BoxDecoration;
            if (d.color == AppColors.errorDark ||
                d.color == AppColors.success ||
                d.color == AppColors.primaryTrueDark) {
              return d.color;
            }
          }
        }
        return null;
      }

      await tester.pumpWidget(
        buildApp(
          child: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () =>
                      AppSnackBar.showError(context, message: 'Error msg'),
                  child: const Text('TrigError'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      AppSnackBar.showSuccess(context, message: 'Success msg'),
                  child: const Text('TrigSuccess'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      AppSnackBar.showInfo(context, message: 'Info msg'),
                  child: const Text('TrigInfo'),
                ),
              ],
            ),
          ),
        ),
      );

      // Error → errorDark
      await tester.tap(find.text('TrigError'));
      await tester.pump();
      expect(findSnackBarColor(tester), AppColors.errorDark);

      // Success → success
      await tester.tap(find.text('TrigSuccess'));
      await tester.pump();
      expect(findSnackBarColor(tester), AppColors.success);

      // Info → primaryTrueDark
      await tester.tap(find.text('TrigInfo'));
      await tester.pump();
      expect(findSnackBarColor(tester), AppColors.primaryTrueDark);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('no contamination between independent scopes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              Expanded(
                child: SnackBarScope(
                  child: Scaffold(
                    body: Builder(
                      builder: (context) => ElevatedButton(
                        onPressed: () =>
                            AppSnackBar.showError(context, message: 'Scope A'),
                        child: const Text('TriggerA'),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SnackBarScope(
                  child: Scaffold(
                    body: Builder(
                      builder: (context) => ElevatedButton(
                        onPressed: () =>
                            AppSnackBar.showError(context, message: 'Scope B'),
                        child: const Text('TriggerB'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Trigger scope A
      await tester.tap(find.text('TriggerA'));
      await tester.pump();
      expect(find.text('Scope A'), findsOneWidget);

      // Trigger scope B — scope A should still be visible (independent)
      await tester.tap(find.text('TriggerB'));
      await tester.pump();
      expect(find.text('Scope A'), findsOneWidget);
      expect(find.text('Scope B'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
