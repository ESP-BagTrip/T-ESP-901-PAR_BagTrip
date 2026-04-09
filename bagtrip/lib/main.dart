import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
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
import 'package:bagtrip/core/app_lifecycle_observer.dart';
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

  // Local notifications for foreground display + deep link handler
  await LocalNotificationService.initialize(
    onNotificationTap: _handleLocalNotificationTap,
  );

  // Offline cache
  await CacheService.initialize();
  await getIt<ConnectivityService>().initialize();

  runApp(const MyApp());
}

void _handleLocalNotificationTap(String? payload) {
  if (payload == null) return;
  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final screen = data['screen'] as String?;
    final tripId = data['tripId'] as String?;
    if (tripId == null) return;

    final path = switch (screen) {
      'activities' => '/home/$tripId/activities',
      'baggage' => '/home/$tripId/baggage',
      'budget' => '/home/$tripId/budget',
      _ => '/home/$tripId',
    };
    appRouter.go(path);
  } catch (e) {
    dev.log('Local notification tap handler error: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<RemoteMessage> _onMessageSub;
  late final StreamSubscription<String> _onTokenRefreshSub;
  late final HomeBloc _homeBloc;
  late final AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _homeBloc = HomeBloc();
    _lifecycleObserver = AppLifecycleObserver(
      onResumed: () {
        if (_homeBloc.state is! HomeInitial && !_homeBloc.isClosed) {
          _homeBloc.add(RefreshHome());
        }
      },
    );
    _lifecycleObserver.initialize();
    _setupFCMListeners();
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    _homeBloc.close();
    _onMessageSub.cancel();
    _onTokenRefreshSub.cancel();
    getIt<ConnectivityService>().dispose();
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
        BlocProvider.value(value: _homeBloc),
        BlocProvider(create: (context) => NotificationBloc()),
        BlocProvider(create: (context) => ConnectivityBloc()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        // Reset all user-scoped blocs when the authenticated user changes,
        // otherwise stale data from the previous session leaks across logout/login
        // (HomeBloc, UserProfileBloc, etc. only refetch when their state is Initial).
        listenWhen: (prev, curr) {
          // login (any non-success → success)
          if (curr is AuthSuccess && prev is! AuthSuccess) return true;
          // logout (loading → initial)
          if (curr is AuthInitial && prev is AuthLoading) return true;
          return false;
        },
        listener: (context, state) {
          context.read<HomeBloc>().add(ResetHome());
          context.read<UserProfileBloc>().add(ResetUserProfile());
          context.read<TripManagementBloc>().add(ResetTripManagement());
          context.read<NotificationBloc>().add(ResetNotifications());
        },
        child: AuthListener(
          router: appRouter,
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              final ThemeMode themeMode = switch (settingsState.selectedTheme) {
                'dark' => ThemeMode.dark,
                'light' => ThemeMode.light,
                _ => ThemeMode.system,
              };
              final Locale locale = switch (settingsState.selectedLanguage) {
                'English' => const Locale('en'),
                _ => const Locale('fr'),
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
                locale: locale,
                routerConfig: appRouter,
                scrollBehavior: const _AdaptiveScrollBehavior(),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              );
            },
          ),
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
