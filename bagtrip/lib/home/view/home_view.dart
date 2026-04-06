import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/active_trip_home_view.dart';
import 'package:bagtrip/home/view/idle_home_view.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
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
        child: MultiBlocListener(
          listeners: [
            BlocListener<HomeBloc, HomeState>(
              listenWhen: (prev, curr) =>
                  prev is HomeIdle && curr is HomeActiveTrip,
              listener: (context, state) => AppHaptics.success(),
            ),
            BlocListener<HomeBloc, HomeState>(
              listenWhen: (prev, curr) {
                if (curr is HomeActiveTrip && curr.completedTripId != null) {
                  return true;
                }
                return false;
              },
              listener: (context, state) {
                if (state is HomeActiveTrip && state.completedTripId != null) {
                  AppHaptics.success();
                  PostTripRoute(tripId: state.completedTripId!).push(context);
                }
              },
            ),
          ],
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, homeState) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: AppAnimations.springCurve,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _buildTransition,
                child: _buildContent(context, homeState),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeState state) {
    return switch (state) {
      HomeLoading() ||
      HomeInitial() => const LoadingView(key: ValueKey('home-loading')),
      HomeError(:final error) => ErrorView(
        key: const ValueKey('home-error'),
        message: toUserFriendlyMessage(error, AppLocalizations.of(context)!),
        onRetry: () => context.read<HomeBloc>().add(LoadHome()),
      ),
      HomeIdle() => RefreshIndicator(
        key: const ValueKey('home-idle'),
        onRefresh: () => _refresh(context),
        child: IdleHomeView(state: state),
      ),
      HomeActiveTrip() => RefreshIndicator(
        key: const ValueKey('home-active-trip'),
        onRefresh: () => _refresh(context),
        child: ActiveTripHomeView(state: state),
      ),
    };
  }

  Future<void> _refresh(BuildContext context) async {
    context.read<HomeBloc>().add(RefreshHome());
    for (final s in ['ongoing', 'planned', 'completed']) {
      context.read<TripManagementBloc>().add(LoadTripsByStatus(status: s));
    }
  }
}
