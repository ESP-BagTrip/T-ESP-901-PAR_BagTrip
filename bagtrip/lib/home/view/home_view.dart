import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/active_trip_home_view.dart';
import 'package:bagtrip/home/view/onboarding_home_view.dart';
import 'package:bagtrip/home/view/trip_manager_home_view.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            if (homeState is HomeLoading || homeState is HomeInitial) {
              return const LoadingView();
            }

            if (homeState is HomeError) {
              return ErrorView(
                message: toUserFriendlyMessage(
                  homeState.error,
                  AppLocalizations.of(context)!,
                ),
                onRetry: () => context.read<HomeBloc>().add(LoadHome()),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(RefreshHome());
                for (final s in ['ongoing', 'planned', 'completed']) {
                  context.read<TripManagementBloc>().add(
                    LoadTripsByStatus(status: s),
                  );
                }
              },
              child: switch (homeState) {
                HomeNewUser() => OnboardingHomeView(state: homeState),
                HomeActiveTrip() => ActiveTripHomeView(state: homeState),
                HomeTripManager() => TripManagerHomeView(state: homeState),
                _ => const LoadingView(),
              },
            );
          },
        ),
      ),
    );
  }
}
