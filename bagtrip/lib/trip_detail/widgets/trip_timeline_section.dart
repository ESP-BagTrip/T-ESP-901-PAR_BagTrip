import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/day_grouping.dart';
import 'package:bagtrip/trip_detail/widgets/timeline_activity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TripTimelineSection extends StatelessWidget {
  final Trip trip;
  final List<Activity> activities;
  final int selectedDayIndex; // 0-based
  final int totalDays;
  final bool isOwner;
  final bool isCompleted;
  final String tripId;

  const TripTimelineSection({
    super.key,
    required this.trip,
    required this.activities,
    required this.selectedDayIndex,
    required this.totalDays,
    required this.isOwner,
    required this.isCompleted,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final grouped = groupActivitiesByDay(
      activities: activities,
      tripStartDate: trip.startDate!,
      totalDays: totalDays,
    );

    final dayData = grouped[selectedDayIndex + 1] ?? const DayActivities();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────
        _SectionHeader(title: l10n.timelineSectionTitle),
        const SizedBox(height: 12),

        // ── Day chip row ────────────────────────────────────────
        _DayChipRow(
          totalDays: totalDays,
          selectedIndex: selectedDayIndex,
          tripStartDate: trip.startDate!,
          currentDay: _currentDayNumber,
        ),
        const SizedBox(height: 16),

        // ── Day content with page-turn animation ────────────────
        AnimatedSwitcher(
          duration: AppAnimations.cardTransition,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _DayContent(
            key: ValueKey(selectedDayIndex),
            dayData: dayData,
            isOwner: isOwner,
            isCompleted: isCompleted,
            tripId: tripId,
            trip: trip,
            l10n: l10n,
          ),
        ),
      ],
    );
  }

  int? get _currentDayNumber {
    if (trip.startDate == null || trip.endDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      trip.startDate!.year,
      trip.startDate!.month,
      trip.startDate!.day,
    );
    final diff = today.difference(start).inDays;
    if (diff < 0 || diff >= totalDays) return null;
    return diff; // 0-based to match selectedDayIndex
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.hiking_rounded, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Day Chip Row ─────────────────────────────────────────────────────────────

class _DayChipRow extends StatelessWidget {
  final int totalDays;
  final int selectedIndex;
  final DateTime tripStartDate;
  final int? currentDay;

  const _DayChipRow({
    required this.totalDays,
    required this.selectedIndex,
    required this.tripStartDate,
    this.currentDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM');

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: totalDays,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = i == selectedIndex;
          final isCurrent = currentDay != null && i == currentDay;
          final date = tripStartDate.add(Duration(days: i));

          return GestureDetector(
            onTap: () {
              AppHaptics.light();
              context.read<TripDetailBloc>().add(SelectDay(dayIndex: i));
            },
            child: AnimatedContainer(
              duration: AppAnimations.microInteraction,
              curve: AppAnimations.standardCurve,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: AppRadius.large16,
                border: isSelected
                    ? null
                    : Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'J${i + 1}',
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    dateFormat.format(date),
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : theme.colorScheme.outline,
                    ),
                  ),
                  if (isCurrent && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Day Content ──────────────────────────────────────────────────────────────

class _DayContent extends StatelessWidget {
  final DayActivities dayData;
  final bool isOwner;
  final bool isCompleted;
  final String tripId;
  final Trip trip;
  final AppLocalizations l10n;

  const _DayContent({
    super.key,
    required this.dayData,
    required this.isOwner,
    required this.isCompleted,
    required this.tripId,
    required this.trip,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (dayData.isEmpty) {
      return ElegantEmptyState(
        icon: Icons.event_outlined,
        title: l10n.timelineEmptyDayTitle,
        subtitle: l10n.timelineEmptyDaySubtitle,
        ctaLabel: isOwner && !isCompleted ? l10n.addActivity : null,
        onCta: isOwner && !isCompleted
            ? () => _navigateToActivities(context)
            : null,
      );
    }

    // Build time block sections with a running global index for stagger
    var globalIndex = 0;
    final children = <Widget>[];

    if (dayData.allDay.isNotEmpty) {
      children.addAll(
        _buildTimeBlock(
          context: context,
          icon: Icons.calendar_today_outlined,
          label: l10n.activeTripsAllDay,
          activities: dayData.allDay,
          startIndex: globalIndex,
        ),
      );
      globalIndex += dayData.allDay.length;
    }

    if (dayData.morning.isNotEmpty) {
      children.addAll(
        _buildTimeBlock(
          context: context,
          icon: Icons.wb_sunny_outlined,
          label: l10n.timelineMorning,
          activities: dayData.morning,
          startIndex: globalIndex,
        ),
      );
      globalIndex += dayData.morning.length;
    }

    if (dayData.afternoon.isNotEmpty) {
      children.addAll(
        _buildTimeBlock(
          context: context,
          icon: Icons.wb_cloudy_outlined,
          label: l10n.timelineAfternoon,
          activities: dayData.afternoon,
          startIndex: globalIndex,
        ),
      );
      globalIndex += dayData.afternoon.length;
    }

    if (dayData.evening.isNotEmpty) {
      children.addAll(
        _buildTimeBlock(
          context: context,
          icon: Icons.nights_stay_outlined,
          label: l10n.timelineEvening,
          activities: dayData.evening,
          startIndex: globalIndex,
        ),
      );
    }

    // Add activity button for owners
    if (isOwner && !isCompleted) {
      children.add(
        Center(
          child: TextButton.icon(
            onPressed: () => _navigateToActivities(context),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addActivity),
          ),
        ),
      );
    }

    return Column(children: children);
  }

  List<Widget> _buildTimeBlock({
    required BuildContext context,
    required IconData icon,
    required String label,
    required List<Activity> activities,
    required int startIndex,
  }) {
    final theme = Theme.of(context);
    return [
      // Block header
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
      // Activity cards
      for (var i = 0; i < activities.length; i++)
        StaggeredFadeIn(
          index: startIndex + i,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TimelineActivityCard(
              activity: activities[i],
              isOwner: isOwner,
              isCompleted: isCompleted,
              onValidate: () => context.read<TripDetailBloc>().add(
                ValidateActivity(activityId: activities[i].id),
              ),
              onReject: () => context.read<TripDetailBloc>().add(
                RejectActivity(activityId: activities[i].id),
              ),
              onDelete: () => context.read<TripDetailBloc>().add(
                RejectActivity(activityId: activities[i].id),
              ),
            ),
          ),
        ),
    ];
  }

  Future<void> _navigateToActivities(BuildContext context) async {
    await ActivitiesRoute(
      tripId: tripId,
      role: isOwner ? 'OWNER' : 'VIEWER',
      isCompleted: isCompleted,
    ).push(context);
    if (!context.mounted) return;
    context.read<TripDetailBloc>().add(RefreshTripDetail());
  }
}
