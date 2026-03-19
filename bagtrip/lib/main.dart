import 'dart:async';
import 'dart:ui';

import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/auth/widgets/auth_listener.dart';
import 'package:bagtrip/booking/bloc/booking_bloc.dart';
import 'package:bagtrip/components/snack_bar_scope.dart';
import 'package:bagtrip/config/app_config.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/design/app_theme.dart';
import 'package:bagtrip/firebase_options.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/app_router.dart';
import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/service/crashlytics_service.dart';
import 'package:bagtrip/service/local_notification_service.dart';
import 'package:bagtrip/repositories/notification_repository.dart';
import 'package:bagtrip/settings/bloc/settings_bloc.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/cache/connectivity_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Top-level background message handler (required to be a top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  setupServiceLocator();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Stripe
  Stripe.publishableKey = AppConfig.stripePublishableKey;
  Stripe.urlScheme = 'bagtrip';
  await Stripe.instance.applySettings();

  // Crashlytics
  final crashlyticsService = getIt<CrashlyticsService>();
  await crashlyticsService.initialize();
  FlutterError.onError = crashlyticsService.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlyticsService.recordPlatformError(error, stack);
    return true;
  };

  // FCM setup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission();

  // Local notifications for foreground display
  await LocalNotificationService.initialize();

  // Offline cache
  await CacheService.initialize();
  await getIt<ConnectivityService>().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<RemoteMessage> _onMessageSub;
  late final StreamSubscription<String> _onTokenRefreshSub;

  @override
  void initState() {
    super.initState();
    _setupFCMListeners();
  }

  @override
  void dispose() {
    _onMessageSub.cancel();
    _onTokenRefreshSub.cancel();
    super.dispose();
  }

  void _setupFCMListeners() {
    // Foreground messages — show local notification
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
    _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) {
      final platform = AdaptivePlatform.isIOS ? 'ios' : 'android';
      getIt<NotificationRepository>().registerDeviceToken(
        newToken,
        platform: platform,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SettingsBloc()),
        BlocProvider(create: (context) => UserProfileBloc()),
        BlocProvider(create: (context) => BookingBloc()),
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => TripManagementBloc()),
        BlocProvider(create: (context) => HomeBloc()),
        BlocProvider(create: (context) => NotificationBloc()),
        BlocProvider(create: (context) => ConnectivityBloc()),
      ],
      child: AuthListener(
        router: appRouter,
        child: BlocSelector<SettingsBloc, SettingsState, String>(
          selector: (state) => state.selectedTheme,
          builder: (context, selectedTheme) {
            final ThemeMode themeMode = switch (selectedTheme) {
              'dark' => ThemeMode.dark,
              'light' => ThemeMode.light,
              _ => ThemeMode.system,
            };

            return MaterialApp.router(
              builder: (context, child) =>
                  SnackBarScope(child: child ?? const SizedBox.shrink()),
              theme: AppTheme.light().copyWith(
                cupertinoOverrideTheme: AppTheme.cupertinoLight(),
              ),
              darkTheme: AppTheme.dark().copyWith(
                cupertinoOverrideTheme: AppTheme.cupertinoDark(),
              ),
              themeMode: themeMode,
              routerConfig: appRouter,
              scrollBehavior: const _AdaptiveScrollBehavior(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            );
          },
        ),
      ),
    );
  }
}

/// Adaptive scroll behavior: bouncing on iOS, glow on Android.
class _AdaptiveScrollBehavior extends ScrollBehavior {
  const _AdaptiveScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return AdaptivePlatform.isIOS
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (AdaptivePlatform.isIOS) return child;
    return super.buildOverscrollIndicator(context, child, details);
  }
}
