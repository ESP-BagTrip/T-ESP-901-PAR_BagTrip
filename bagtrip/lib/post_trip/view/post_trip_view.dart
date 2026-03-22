import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/post_trip/bloc/post_trip_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostTripView extends StatelessWidget {
  final String tripId;

  const PostTripView({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PostTripBloc, PostTripState>(
        builder: (context, state) {
          return switch (state) {
            PostTripLoading() || PostTripInitial() => const LoadingView(),
            PostTripError(:final error) => ErrorView(
              message: toUserFriendlyMessage(
                error,
                AppLocalizations.of(context)!,
              ),
              onRetry: () => context.read<PostTripBloc>().add(
                LoadPostTripStats(tripId: tripId),
              ),
            ),
            PostTripLoaded() => _PostTripContent(state: state, tripId: tripId),
          };
        },
      ),
    );
  }
}

class _PostTripContent extends StatelessWidget {
  final PostTripLoaded state;
  final String tripId;

  const _PostTripContent({required this.state, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    int fadeIndex = 0;

    return CustomScrollView(
      slivers: [
        // SliverAppBar with cover
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              l10n.postTripSouvenirsTitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontWeight: FontWeight.w700,
              ),
            ),
            background: state.trip.coverImageUrl != null
                ? OptimizedImage.tripCover(
                    state.trip.coverImageUrl!,
                    colorBlendMode: Colors.black.withValues(alpha: 0.3),
                    blendMode: BlendMode.darken,
                  )
                : ColoredBox(color: theme.colorScheme.primaryContainer),
          ),
        ),

        // Trip title + destination
        SliverToBoxAdapter(
          child: StaggeredFadeIn(
            index: fadeIndex++,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space24,
                AppSpacing.space24,
                AppSpacing.space24,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.trip.title ?? state.destinationName,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (state.destinationName.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      state.destinationName,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Stats grid 2x2
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space24,
              AppSpacing.space24,
              AppSpacing.space24,
              0,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StaggeredFadeIn(
                        index: fadeIndex++,
                        child: _StatCard(
                          icon: Icons.calendar_today_rounded,
                          label: l10n.postTripDaysCount(state.totalDays),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: StaggeredFadeIn(
                        index: fadeIndex++,
                        child: _StatCard(
                          icon: Icons.check_circle_outline_rounded,
                          label: l10n.postTripActivitiesCompleted(
                            state.activitiesCompleted,
                            state.totalActivities,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space12),
                Row(
                  children: [
                    Expanded(
                      child: StaggeredFadeIn(
                        index: fadeIndex++,
                        child: _StatCard(
                          icon: Icons.wallet_rounded,
                          label: l10n.postTripBudgetSpent(
                            '${state.budgetSpent.toStringAsFixed(0)}\u20ac',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: StaggeredFadeIn(
                        index: fadeIndex++,
                        child: _StatCard(
                          icon: Icons.explore_rounded,
                          label: l10n.postTripCategoriesExplored(
                            state.categoriesExplored
                                .where((c) => c != ActivityCategory.other)
                                .length,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // CTA: Give review
        SliverToBoxAdapter(
          child: StaggeredFadeIn(
            index: fadeIndex++,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space24,
                AppSpacing.space32,
                AppSpacing.space24,
                0,
              ),
              child: FilledButton.icon(
                onPressed: () {
                  AppHaptics.light();
                  FeedbackRoute(tripId: tripId).push(context);
                },
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(l10n.postTripGiveReview),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space16,
                  ),
                ),
              ),
            ),
          ),
        ),

        // CTA: Plan next trip
        SliverToBoxAdapter(
          child: StaggeredFadeIn(
            index: fadeIndex++,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space24,
                AppSpacing.space12,
                AppSpacing.space24,
                0,
              ),
              child: OutlinedButton.icon(
                onPressed: () {
                  AppHaptics.light();
                  const TripCreationRoute().push(context);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.postTripPlanNext),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space16,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(
            height: AdaptivePlatform.isIOS ? 100 : AppSpacing.space32,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.large16),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: AppSpacing.allEdgeInsetSpace16,
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(height: AppSpacing.space8),
            Text(
              label,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
