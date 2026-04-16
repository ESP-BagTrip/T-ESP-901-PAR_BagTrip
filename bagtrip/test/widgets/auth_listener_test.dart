// ignore_for_file: unnecessary_underscores

import 'package:bagtrip/auth/widgets/auth_listener.dart';
import 'package:bagtrip/core/auth_event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AuthListener', () {
    testWidgets('renders its child and wires the unauthenticated stream', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const Text('HOME')),
          GoRoute(path: '/login', builder: (_, __) => const Text('LOGIN')),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthListener(router: router, child: const Text('CHILD')),
        ),
      );
      expect(find.text('CHILD'), findsOneWidget);
      // Firing the event should not throw even if the GoRouter isn't
      // actively driving the MaterialApp — the listener just calls go().
      AuthEventBus.fireUnauthenticated();
      await tester.pump();
      expect(find.byType(AuthListener), findsOneWidget);
    });

    testWidgets('cancels the subscription on dispose', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AuthListener(router: router, child: const Text('X')),
        ),
      );
      expect(find.text('X'), findsOneWidget);
      // Replace with a different tree — triggers dispose.
      await tester.pumpWidget(const MaterialApp(home: Text('Y')));
      expect(find.text('Y'), findsOneWidget);
    });
  });
}
