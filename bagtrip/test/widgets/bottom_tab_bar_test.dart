import 'package:bagtrip/components/bottom_tab_bar.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomTabBar', () {
    Widget buildSubject({
      NavigationTab activeTab = NavigationTab.home,
      ValueChanged<NavigationTab>? onTabChanged,
      int activityBadgeCount = 0,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: BottomTabBar(
            activeTab: activeTab,
            onTabChanged: onTabChanged ?? (_) {},
            activityBadgeCount: activityBadgeCount,
          ),
        ),
      );
    }

    testWidgets('renders 3 navigation destinations', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget);

      final widget = tester.widget<NavigationBar>(navBar);
      expect(widget.destinations.length, 3);
    });

    testWidgets('selected index matches home tab', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);
    });

    testWidgets('selected index is 1 for activity tab', (tester) async {
      await tester.pumpWidget(buildSubject(activeTab: NavigationTab.activity));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 1);
    });

    testWidgets('selected index is 2 for profile tab', (tester) async {
      await tester.pumpWidget(buildSubject(activeTab: NavigationTab.profile));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 2);
    });

    testWidgets('onDestinationSelected triggers onTabChanged', (tester) async {
      NavigationTab? tappedTab;

      await tester.pumpWidget(
        buildSubject(onTabChanged: (tab) => tappedTab = tab),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      navBar.onDestinationSelected?.call(0);

      expect(tappedTab, NavigationTab.home);
    });

    testWidgets('onDestinationSelected fires activity for index 1', (
      tester,
    ) async {
      NavigationTab? tappedTab;

      await tester.pumpWidget(
        buildSubject(onTabChanged: (tab) => tappedTab = tab),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      navBar.onDestinationSelected?.call(1);

      expect(tappedTab, NavigationTab.activity);
    });

    testWidgets('onDestinationSelected fires profile for index 2', (
      tester,
    ) async {
      NavigationTab? tappedTab;

      await tester.pumpWidget(
        buildSubject(onTabChanged: (tab) => tappedTab = tab),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      navBar.onDestinationSelected?.call(2);

      expect(tappedTab, NavigationTab.profile);
    });

    testWidgets('badge is visible when activityBadgeCount > 0', (tester) async {
      await tester.pumpWidget(buildSubject(activityBadgeCount: 5));
      await tester.pumpAndSettle();

      expect(find.byType(Badge), findsWidgets);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('badge is not visible when activityBadgeCount is 0', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Badge widgets exist but isLabelVisible is false
      final badges = tester.widgetList<Badge>(find.byType(Badge));
      for (final badge in badges) {
        expect(badge.isLabelVisible, isFalse);
      }
    });
  });
}
