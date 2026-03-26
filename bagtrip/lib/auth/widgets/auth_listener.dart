import 'dart:async';

import 'package:bagtrip/core/auth_event_bus.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class AuthListener extends StatefulWidget {
  final GoRouter router;
  final Widget child;

  const AuthListener({super.key, required this.router, required this.child});

  @override
  State<AuthListener> createState() => _AuthListenerState();
}

class _AuthListenerState extends State<AuthListener> {
  late final StreamSubscription<void> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = AuthEventBus.onUnauthenticated.listen((_) {
      widget.router.go('/login');
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
