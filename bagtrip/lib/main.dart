import 'package:bagtrip/design/app_theme.dart';
import 'package:bagtrip/firebase_options.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/app_router.dart';
import 'package:bagtrip/profile/bloc/profile_bloc.dart';
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
    return BlocProvider(
      create: (context) => ProfileBloc()..add(LoadProfile()),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          // Get theme from state or default to 'light'
          String themeValue = 'light';
          if (state is ProfileLoaded) {
            themeValue = state.selectedTheme;
          }

          // Convert theme string to ThemeMode
          ThemeMode themeMode;
          switch (themeValue) {
            case 'dark':
              themeMode = ThemeMode.dark;
              break;
            case 'system':
              themeMode = ThemeMode.system;
              break;
            case 'light':
            default:
              themeMode = ThemeMode.light;
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
