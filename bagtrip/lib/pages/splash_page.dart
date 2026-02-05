import 'package:bagtrip/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Écran de chargement au démarrage : valide le token via l'API puis
/// redirige vers /home si connecté, sinon vers /login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAuthAndNavigate(),
    );
  }

  Future<void> _checkAuthAndNavigate() async {
    final authService = AuthService();
    final user = await authService.getCurrentUser();

    if (!mounted) return;

    if (user != null) {
      context.go('/home');
    } else {
      await authService.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
