import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Path segment watched by [ActiveTripHomeView] for post-programme tap guard.
const kTestActiveTripProgrammePath = '/home/active-trip/programme';

/// Minimal [GoRouter] for widget tests that call [GoRouter.of] without the
/// full app router (e.g. active trip hero route listeners).
GoRouter testGoRouter({required Widget home, String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: kTestActiveTripProgrammePath,
        builder: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );
}

/// [MaterialApp.router] with l10n and a [testGoRouter] around [child].
Widget localizedRouterApp({
  required Widget child,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    routerConfig: testGoRouter(home: child),
  );
}

/// Pumps a widget wrapped in a minimal `MaterialApp` with localizations
/// delegates registered. Use this for smoke tests that only need a
/// localized, themed context.
///
/// The child is wrapped in a `Material` ancestor so that widgets like
/// TabBar/Ink/TextField/ListTile that require a Material in their ancestor
/// chain work even when the child itself does not build a Scaffold. If the
/// child already renders a Scaffold, nesting Material is a no-op.
///
/// Need multiple BlocProviders? Wrap the `child` yourself in
/// `MultiBlocProvider` before passing it in — that keeps this helper free
/// of flutter_bloc-specific types.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  Size? size,
  ThemeData? theme,
}) async {
  if (size != null) {
    tester.view.physicalSize = Size(size.width, size.height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Material(child: child),
    ),
  );
}
