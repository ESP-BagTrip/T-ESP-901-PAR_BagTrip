import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:bagtrip/components/bottom_tab_bar.dart';
import 'package:bagtrip/pages/home_page.dart';
import 'package:bagtrip/pages/map_page.dart';
import 'package:bagtrip/pages/budget_page.dart';
import 'package:bagtrip/pages/profile_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NavigationBloc(),
      child: const AppShellContent(),
    );
  }
}

class AppShellContent extends StatelessWidget {
  const AppShellContent({super.key});

  Widget _buildPageByTab(NavigationTab tab) {
    switch (tab) {
      case NavigationTab.home:
        return const HomePage();
      case NavigationTab.map:
        return const MapPage();
      case NavigationTab.budget:
        return const BudgetPage();
      case NavigationTab.profile:
        return const ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: _buildPageByTab(state.activeTab),
          bottomNavigationBar: BottomTabBar(
            activeTab: state.activeTab,
            onTabChanged: (tab) {
              context.read<NavigationBloc>().add(NavigationTabChanged(tab));
            },
          ),
        );
      },
    );
  }
}
