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
import 'package:bagtrip/notifications/cubit/notification_count_cubit.dart';
import 'package:bagtrip/notifications/notification_deep_link.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/service/crashlytics_service.dart';
import 'package:bagtrip/service/local_notification_service.dart';
import 'package:bagtrip/repositories/notification_repository.dart';
import 'package:bagtrip/settings/bloc/settings_bloc.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/subscription/bloc/subscription_bloc.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/cache/connectivity_bloc.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
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

  // Stripe — fail loudly if the publishable key wasn't injected via
  // `--dart-define=STRIPE_PUBLISHABLE_KEY=...`. Stripe's SDK accepts the
  // placeholder silently, then any PaymentSheet call dies with a cryptic
  // error. `debugPrint` (not `dev.log`) so the warning lands in the
  // standard `flutter run` output regardless of log level filtering.
  final stripeKey = AppConfig.stripePublishableKey;
  if (stripeKey.isEmpty ||
      stripeKey == 'STRIPE_KEY_NOT_SET' ||
      !stripeKey.startsWith('pk_')) {
    debugPrint(
      '🛑 [Stripe] STRIPE_PUBLISHABLE_KEY missing or invalid '
      '("${stripeKey.isEmpty ? "<empty>" : stripeKey}"). '
      'Pass it via `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_…` '
      '(the Makefile does this from .env). PaymentSheet flows will fail.',
    );
  } else {
    debugPrint(
      '✅ [Stripe] using publishable key '
      '${stripeKey.substring(0, 8)}…${stripeKey.substring(stripeKey.length - 4)}',
    );
  }
  Stripe.publishableKey = stripeKey;
  Stripe.urlScheme = 'bagtrip';
  // Apple Pay merchant identifier — must match the one configured in
  // Apple Developer + the Stripe dashboard + the Xcode "Apple Pay"
  // capability (Runner.entitlements). Empty default is harmless: the
  // PaymentSheet just won't render the Apple Pay row on iOS until the
  // merchant id ships.
  if (AppConfig.appleMerchantIdentifier.isNotEmpty) {
    Stripe.merchantIdentifier = AppConfig.appleMerchantIdentifier;
  }
  await Stripe.instance.applySettings();

  // Crashlytics
  final crashlyticsService = getIt<CrashlyticsService>();
  await crashlyticsService.initialize();
  FlutterError.onError = crashlyticsService.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlyticsService.recordPlatformError(error, stack);
    return true;
  };

  // FCM setup — notification permission is requested contextually after the
  // user authenticates (see AuthBloc), not at cold start before they've even
  // seen the app.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notifications for foreground display + deep link handler
  await LocalNotificationService.initialize(
    onNotificationTap: _handleLocalNotificationTap,
  );

  // Offline cache
  await CacheService.initialize();
  await getIt<ConnectivityService>().initialize();
  // Replay queued offline writes automatically when connectivity returns.
  getIt<OfflineWriteQueue>().startListening();

  runApp(const MyApp());
}

/// Routes a tap on a foreground-relayed local notification.
void _handleLocalNotificationTap(String? payload) {
  if (payload == null) return;
  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final route = resolveNotificationRoute(data);
    if (route != null) appRouter.go(route);
  } catch (e) {
    dev.log('Local notification tap handler error: $e');
  }
}

/// Routes a tap on an FCM push received in the background or that cold-started
/// the app from a terminated state.
void _handleRemoteMessageTap(RemoteMessage message) {
  final route = resolveNotificationRoute(message.data);
  if (route != null) appRouter.go(route);
}

/// Stable, positive notification id derived from the FCM message id — avoids
/// the collisions of using the [RemoteMessage] object's `hashCode`.
int _foregroundNotificationId(RemoteMessage message) =>
    (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) &
    0x7FFFFFFF;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<RemoteMessage> _onMessageSub;
  late final StreamSubscription<RemoteMessage> _onMessageOpenedSub;
  late final StreamSubscription<String> _onTokenRefreshSub;
  late final HomeBloc _homeBloc;
  late final NotificationCountCubit _countCubit;
  late final AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _homeBloc = HomeBloc();
    _countCubit = NotificationCountCubit();
    _lifecycleObserver = AppLifecycleObserver(
      onResumed: () {
        if (_homeBloc.state is! HomeInitial && !_homeBloc.isClosed) {
          _homeBloc.add(RefreshHome());
        }
        _countCubit.refresh();
      },
    );
    _lifecycleObserver.initialize();
    _setupFCMListeners();
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    _homeBloc.close();
    _countCubit.close();
    _onMessageSub.cancel();
    _onMessageOpenedSub.cancel();
    _onTokenRefreshSub.cancel();
    getIt<ConnectivityService>().dispose();
    super.dispose();
  }

  void _setupFCMListeners() {
    // Foreground messages — FCM draws no banner itself, so relay through a
    // local notification, carrying `data` as the payload so a tap deep-links.
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        LocalNotificationService.show(
          id: _foregroundNotificationId(message),
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: message.data,
        );
      }
      // A push just landed — keep the tab-bar badge live.
      _countCubit.refresh();
    });

    // Tap on a push received while the app was in the background.
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleRemoteMessageTap,
    );

    // App cold-started by tapping a push from a terminated state.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleRemoteMessageTap(message);
    });

    // Token refresh — re-register with backend
    _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) {
      final platform = AdaptivePlatform.isIOS ? 'ios' : 'android';
      getIt<NotificationRepository>().registerDeviceToken(
        newToken,
        platform: platform,
        locale: PlatformDispatcher.instance.locale.languageCode,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SettingsBloc()),
        BlocProvider(create: (context) => UserProfileBloc()),
        BlocProvider(create: (context) => AuthBloc()),
        // BookingBloc consumes AuthBloc so payment success can refresh the
        // user. Order matters — AuthBloc must be available above.
        BlocProvider(
          create: (context) => BookingBloc(authBloc: context.read<AuthBloc>()),
        ),
        BlocProvider(create: (context) => TripManagementBloc()),
        BlocProvider.value(value: _homeBloc),
        BlocProvider(create: (context) => NotificationBloc()),
        BlocProvider.value(value: _countCubit),
        BlocProvider(create: (context) => ConnectivityBloc()),
        // App-level so paywalls / gating / subscription page all read from
        // a single source of truth instead of polling endpoints separately.
        BlocProvider(
          create: (context) =>
              SubscriptionBloc(authBloc: context.read<AuthBloc>()),
        ),
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
          context.read<SubscriptionBloc>().add(ResetSubscription());
          // Refresh the unread badge on login, drop it on logout.
          if (state is AuthSuccess) {
            _countCubit.refresh();
          } else {
            _countCubit.clear();
          }
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
