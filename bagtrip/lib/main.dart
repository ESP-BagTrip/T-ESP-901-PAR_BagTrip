import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/navigation/app_router.dart';
import 'package:bagtrip/design/app_theme.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/logic/auth_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthService(),
      child: BlocProvider(
        create: (context) => AuthBloc(
          authService: context.read<AuthService>(),
        )..add(AuthAppStarted()),
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: createRouter(context.read<AuthBloc>()),
    );
  }
}
