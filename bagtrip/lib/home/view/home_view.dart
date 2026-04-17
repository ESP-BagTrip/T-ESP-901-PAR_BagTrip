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
import 'package:shimmer/shimmer.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _topShimmer = false;

  Future<void> _onPullRefresh() async {
    if (!mounted) return;
    setState(() => _topShimmer = true);
    try {
      await Future.wait([
        _refreshData(),
        Future<void>.delayed(const Duration(milliseconds: 750)),
      ]);
    } finally {
      if (mounted) setState(() => _topShimmer = false);
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    context.read<HomeBloc>().add(RefreshHome());
    for (final s in ['ongoing', 'planned', 'completed']) {
      context.read<TripManagementBloc>().add(LoadTripsByStatus(status: s));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, homeState) {
        final stack = Stack(
          clipBehavior: Clip.none,
          children: [
            MultiBlocListener(
              listeners: [
                BlocListener<HomeBloc, HomeState>(
                  listenWhen: (prev, curr) =>
                      prev is HomeIdle && curr is HomeActiveTrip,
                  listener: (context, state) => AppHaptics.success(),
                ),
                BlocListener<HomeBloc, HomeState>(
                  listenWhen: (prev, curr) {
                    if (curr is HomeActiveTrip &&
                        curr.completedTripId != null) {
                      return true;
                    }
                    return false;
                  },
                  listener: (context, state) {
                    if (state is HomeActiveTrip &&
                        state.completedTripId != null) {
                      AppHaptics.success();
                      PostTripRoute(
                        tripId: state.completedTripId!,
                      ).push(context);
                    }
                  },
                ),
              ],
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: AppAnimations.springCurve,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _buildTransition,
                child: _buildContent(context, homeState),
              ),
            ),
            if (_topShimmer)
              Positioned(
                top: homeState is HomeActiveTrip
                    ? MediaQuery.paddingOf(context).top
                    : 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 3,
                  width: double.infinity,
                  child: Shimmer.fromColors(
                    baseColor: const Color(0xFF34B7A4).withValues(alpha: 0.35),
                    highlightColor: const Color(0xFF9EE8DC),
                    period: const Duration(milliseconds: 1100),
                    child: Container(height: 3, color: const Color(0xFF34B7A4)),
                  ),
                ),
              ),
          ],
        );

        return Scaffold(
          body: homeState is HomeActiveTrip ? stack : SafeArea(child: stack),
        );
      },
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
        color: Colors.transparent,
        backgroundColor: Colors.transparent,
        strokeWidth: 2,
        displacement: 48,
        onRefresh: _onPullRefresh,
        child: IdleHomeView(state: state),
      ),
      HomeActiveTrip() => RefreshIndicator(
        key: const ValueKey('home-active-trip'),
        color: Colors.transparent,
        backgroundColor: Colors.transparent,
        strokeWidth: 2,
        displacement: 48,
        onRefresh: _onPullRefresh,
        child: ActiveTripHomeView(state: state),
      ),
    };
  }
}
