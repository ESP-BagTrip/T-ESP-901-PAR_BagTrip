import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:bagtrip/trips/widgets/trip_section_card.dart';
import 'package:bagtrip/trips/widgets/trip_header.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/navigation/route_definitions.dart';

class TripHomeView extends StatelessWidget {
  final String tripId;

  const TripHomeView({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<TripManagementBloc, TripManagementState>(
        listener: (context, state) {
          if (state is TripsLoaded || state is TripDeleted) {
            const HomeRoute().go(context);
          }
          if (state is TripError) {
            AppSnackBar.showError(
              context,
              message: toUserFriendlyMessage(
                state.error,
                AppLocalizations.of(context)!,
              ),
            );
            context.read<TripManagementBloc>().add(
              LoadTripHome(tripId: tripId),
            );
          }
        },
        builder: (context, state) {
          if (state is TripHomeLoading) {
            return const LoadingView();
          }

          if (state is TripError) {
            return ErrorView(
              message: toUserFriendlyMessage(
                state.error,
                AppLocalizations.of(context)!,
              ),
              onRetry: () => context.read<TripManagementBloc>().add(
                LoadTripHome(tripId: tripId),
              ),
            );
          }

          if (state is TripHomeLoaded) {
            final tripHome = state.tripHome;
            final trip = tripHome.trip;
            final stats = tripHome.stats;
            final l10n = AppLocalizations.of(context)!;
            final isViewer = trip.role == 'VIEWER';
            final isCompleted = trip.status == TripStatus.completed;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      TripHeader(
                        trip: trip,
                        daysUntilTrip: stats.daysUntilTrip,
                      ),
                      Positioned(
                        top:
                            MediaQuery.of(context).padding.top +
                            AppSpacing.space8,
                        left: AppSpacing.space8,
                        child: IconButton(
                          icon: Icon(
                            AdaptivePlatform.isIOS
                                ? CupertinoIcons.back
                                : Icons.arrow_back,
                            color: AppColors.white,
                          ),
                          onPressed: () => const HomeRoute().go(context),
                        ),
                      ),
                      if (!isViewer)
                        Positioned(
                          top:
                              MediaQuery.of(context).padding.top +
                              AppSpacing.space8,
                          right: AppSpacing.space8,
                          child: IconButton(
                            icon: Icon(
                              AdaptivePlatform.isIOS
                                  ? CupertinoIcons.share
                                  : Icons.share,
                              color: AppColors.white,
                            ),
                            onPressed: () =>
                                TripHomeRoute(tripId: tripId).go(context),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCompleted)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                        vertical: AppSpacing.space8,
                      ),
                      padding: AppSpacing.allEdgeInsetSpace12,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, color: AppColors.hint),
                          const SizedBox(width: AppSpacing.space8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.tripCompletedReadOnly,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space24,
                      vertical: AppSpacing.space8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.large20,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowLight,
                            offset: const Offset(0, 2),
                            blurRadius: 12,
                          ),
                          BoxShadow(
                            color: AppColors.shadowFaint,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(
                            icon: Icons.people_rounded,
                            value: '${stats.nbTravelers}',
                            label: AppLocalizations.of(context)!.tripTravelers,
                          ),
                          if (stats.daysUntilTrip != null)
                            _StatItem(
                              icon: Icons.timer_rounded,
                              value: '${stats.daysUntilTrip}',
                              label: AppLocalizations.of(
                                context,
                              )!.tripDaysRemaining,
                            ),
                          if (stats.tripDuration != null)
                            _StatItem(
                              icon: Icons.date_range_rounded,
                              value: '${stats.tripDuration}',
                              label: AppLocalizations.of(
                                context,
                              )!.tripTravelDays,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: AppSpacing.horizontalSpace24,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.space8),
                      StaggeredFadeIn(
                        index: 0,
                        child: TripSectionCard(
                          icon: Icons.flight_rounded,
                          title: l10n.transportsTitle,
                          itemCount: _sectionCount(tripHome, 'transports'),
                          previewItems: _sectionPreviews(
                            tripHome,
                            'transports',
                          ),
                          emptyLabel: l10n.addFirstTransport,
                          onTap: () async {
                            await TransportsRoute(
                              tripId: tripId,
                              role: trip.role ?? 'OWNER',
                              isCompleted: isCompleted,
                            ).push(context);
                            if (context.mounted) {
                              context.read<TripManagementBloc>().add(
                                LoadTripHome(tripId: tripId),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      StaggeredFadeIn(
                        index: 1,
                        child: TripSectionCard(
                          icon: Icons.hotel_rounded,
                          title: l10n.accommodationsTitle,
                          itemCount: _sectionCount(tripHome, 'accommodations'),
                          previewItems: _sectionPreviews(
                            tripHome,
                            'accommodations',
                          ),
                          emptyLabel: l10n.addFirstAccommodation,
                          onTap: () async {
                            await AccommodationsRoute(
                              tripId: tripId,
                              role: trip.role ?? 'OWNER',
                              isCompleted: isCompleted,
                              tripStartDate: trip.startDate?.toIso8601String(),
                              tripEndDate: trip.endDate?.toIso8601String(),
                            ).push(context);
                            if (context.mounted) {
                              context.read<TripManagementBloc>().add(
                                LoadTripHome(tripId: tripId),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      StaggeredFadeIn(
                        index: 2,
                        child: TripSectionCard(
                          icon: Icons.hiking_rounded,
                          title: l10n.activitiesTitle,
                          itemCount: _sectionCount(tripHome, 'activities'),
                          previewItems: _sectionPreviews(
                            tripHome,
                            'activities',
                          ),
                          emptyLabel: l10n.addFirstActivity,
                          onTap: () async {
                            await ActivitiesRoute(
                              tripId: tripId,
                              role: trip.role ?? 'OWNER',
                              isCompleted: isCompleted,
                            ).push(context);
                            if (context.mounted) {
                              context.read<TripManagementBloc>().add(
                                LoadTripHome(tripId: tripId),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      StaggeredFadeIn(
                        index: 3,
                        child: TripSectionCard(
                          icon: Icons.luggage_rounded,
                          title: l10n.baggageTitle,
                          itemCount: _sectionCount(tripHome, 'baggage'),
                          previewItems: _sectionPreviews(tripHome, 'baggage'),
                          emptyLabel: l10n.addFirstBaggage,
                          onTap: () async {
                            await BaggageRoute(
                              tripId: tripId,
                              role: trip.role ?? 'OWNER',
                              isCompleted: isCompleted,
                            ).push(context);
                            if (context.mounted) {
                              context.read<TripManagementBloc>().add(
                                LoadTripHome(tripId: tripId),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      StaggeredFadeIn(
                        index: 4,
                        child: TripSectionCard(
                          icon: Icons.wallet_rounded,
                          title: l10n.budgetTitle,
                          itemCount: _sectionCount(tripHome, 'budget'),
                          previewItems: _sectionPreviews(tripHome, 'budget'),
                          emptyLabel: l10n.addFirstBudget,
                          onTap: () async {
                            await BudgetRoute(
                              tripId: tripId,
                              role: trip.role ?? 'OWNER',
                              isCompleted: isCompleted,
                            ).push(context);
                            if (context.mounted) {
                              context.read<TripManagementBloc>().add(
                                LoadTripHome(tripId: tripId),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      StaggeredFadeIn(
                        index: 5,
                        child: TripSectionCard(
                          icon: Icons.map_rounded,
                          title: l10n.mapTitle,
                          itemCount: 0,
                          previewItems: const [],
                          emptyLabel: l10n.mapComingSoonShort,
                          onTap: () => MapRoute(tripId: tripId).go(context),
                        ),
                      ),
                    ]),
                  ),
                ),
                if (trip.status == TripStatus.draft && !isViewer)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space24,
                        vertical: AppSpacing.space8,
                      ),
                      child: FilledButton.icon(
                        onPressed: () {
                          context.read<TripManagementBloc>().add(
                            UpdateTripStatus(tripId: tripId, status: 'PLANNED'),
                          );
                        },
                        icon: const Icon(Icons.check_circle),
                        label: Text(AppLocalizations.of(context)!.markAsReady),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                if (trip.status == TripStatus.ongoing && !isViewer)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.allEdgeInsetSpace24,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<TripManagementBloc>().add(
                            UpdateTripStatus(
                              tripId: tripId,
                              status: 'COMPLETED',
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(AppLocalizations.of(context)!.tripComplete),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                if (isCompleted)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space24,
                        vertical: AppSpacing.space8,
                      ),
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            FeedbackRoute(tripId: tripId).go(context),
                        icon: const Icon(Icons.rate_review_outlined),
                        label: Text(
                          AppLocalizations.of(context)!.tripGiveReview,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                if (trip.status == TripStatus.draft && !isViewer)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space24,
                        vertical: AppSpacing.space8,
                      ),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showAdaptiveAlertDialog(
                            context: context,
                            title: AppLocalizations.of(
                              context,
                            )!.tripDeleteTitle,
                            content: AppLocalizations.of(
                              context,
                            )!.tripDeleteConfirm,
                            confirmLabel: AppLocalizations.of(
                              context,
                            )!.deleteButton,
                            cancelLabel: AppLocalizations.of(
                              context,
                            )!.cancelButton,
                            isDestructive: true,
                            onConfirm: () {
                              context.read<TripManagementBloc>().add(
                                DeleteTrip(tripId: tripId),
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          AppLocalizations.of(context)!.tripDeleteTitle,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

int _sectionCount(TripHome tripHome, String sectionId) {
  for (final s in tripHome.sections) {
    if (s.sectionId == sectionId) return s.count;
  }
  return 0;
}

List<String> _sectionPreviews(TripHome tripHome, String sectionId) {
  for (final s in tripHome.sections) {
    if (s.sectionId == sectionId) return s.previewItems;
  }
  return [];
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: ColorName.primary, size: 24),
        const SizedBox(height: AppSpacing.space4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorName.primaryTrueDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 11,
            color: ColorName.textMutedLight,
          ),
        ),
      ],
    );
  }
}
