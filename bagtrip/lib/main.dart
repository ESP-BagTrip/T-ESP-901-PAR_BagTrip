import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/design/app_theme.dart';
import 'package:bagtrip/firebase_options.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/app_router.dart';
import 'package:bagtrip/profile/bloc/profile_bloc.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProfileBloc()),
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => TripManagementBloc()),
      ],
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          // Get theme from state or default to system (first launch)
          String themeValue = 'system';
          if (state is ProfileLoaded) {
            themeValue = state.selectedTheme;
          }

          // Convert theme string to ThemeMode
          ThemeMode themeMode;
          switch (themeValue) {
            case 'dark':
              themeMode = ThemeMode.dark;
              break;
            case 'light':
              themeMode = ThemeMode.light;
              break;
            case 'system':
            default:
              themeMode = ThemeMode.system;
              break;
          }

          return MaterialApp.router(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            routerConfig: appRouter,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
