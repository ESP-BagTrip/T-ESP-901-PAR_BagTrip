import 'package:bagtrip/auth/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('AuthTextField', () {
    testWidgets('renders with label + hintText', (tester) async {
      final controller = TextEditingController();
      await pumpLocalized(
        tester,
        SizedBox(
          width: 300,
          child: AuthTextField(
            label: 'Email',
            hintText: 'you@example.com',
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AuthTextField), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders without label when empty', (tester) async {
      final controller = TextEditingController();
      await pumpLocalized(
        tester,
        SizedBox(
          width: 300,
          child: AuthTextField(label: '', controller: controller),
        ),
      );
      await tester.pump();
      expect(find.byType(AuthTextField), findsOneWidget);
    });

    testWidgets('renders error border when hasError is true', (tester) async {
      final controller = TextEditingController();
      await pumpLocalized(
        tester,
        SizedBox(
          width: 300,
          child: AuthTextField(
            label: 'Password',
            controller: controller,
            obscureText: true,
            hasError: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AuthTextField), findsOneWidget);
    });

    testWidgets('renders with prefix and suffix icons', (tester) async {
      final controller = TextEditingController();
      await pumpLocalized(
        tester,
        SizedBox(
          width: 300,
          child: AuthTextField(
            label: 'Password',
            controller: controller,
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: const Icon(Icons.visibility),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
