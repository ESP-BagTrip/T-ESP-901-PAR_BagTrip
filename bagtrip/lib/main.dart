import 'dart:io';

import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/design/app_theme.dart';
import 'package:bagtrip/firebase_options.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/app_router.dart';
import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:bagtrip/profile/bloc/profile_bloc.dart';
import 'package:bagtrip/service/local_notification_service.dart';
import 'package:bagtrip/service/notification_service.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Top-level background message handler (required to be a top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FCM setup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission();

  // Local notifications for foreground display
  await LocalNotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCMListeners();
  }

  void _setupFCMListeners() {
    // Foreground messages — show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        LocalNotificationService.show(
          id: message.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
        );
      }
    });

    // Token refresh — re-register with backend
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      final platform = Platform.isIOS ? 'ios' : 'android';
      getIt<NotificationApiService>().registerDeviceToken(
        newToken,
        platform: platform,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProfileBloc()),
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => TripManagementBloc()),
        BlocProvider(create: (context) => NotificationBloc()),
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
