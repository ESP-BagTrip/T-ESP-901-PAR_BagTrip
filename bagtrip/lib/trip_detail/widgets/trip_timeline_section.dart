import 'package:bagtrip/activities/widgets/activity_form.dart';
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

    // Count suggested activities for batch banner
    final suggestedActivities = activities
        .where((a) => a.validationStatus == ValidationStatus.suggested)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────
        _SectionHeader(title: l10n.timelineSectionTitle),
        const SizedBox(height: 12),

        // ── Batch validate banner ──────────────────────────────
        if (suggestedActivities.isNotEmpty && isOwner && !isCompleted)
          _BatchValidateBanner(
            suggestedCount: suggestedActivities.length,
            suggestedIds: suggestedActivities.map((a) => a.id).toList(),
            tripId: tripId,
            isOwner: isOwner,
            isCompleted: isCompleted,
          ),

        // ── Day chip row (DragTarget enabled) ─────────────────
        _DayChipRow(
          totalDays: totalDays,
          selectedIndex: selectedDayIndex,
          tripStartDate: trip.startDate!,
          currentDay: _currentDayNumber,
          onActivityDrop: (activity, dayIndex) {
            context.read<TripDetailBloc>().add(
              MoveActivityToDay(
                activityId: activity.id,
                targetDayIndex: dayIndex,
              ),
            );
            AppHaptics.medium();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.activityMovedToDay(dayIndex + 1)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
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
            selectedDayIndex: selectedDayIndex,
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

// ── Batch Validate Banner ────────────────────────────────────────────────────

class _BatchValidateBanner extends StatelessWidget {
  final int suggestedCount;
  final List<String> suggestedIds;
  final String tripId;
  final bool isOwner;
  final bool isCompleted;

  const _BatchValidateBanner({
    required this.suggestedCount,
    required this.suggestedIds,
    required this.tripId,
    required this.isOwner,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: AppRadius.large16,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.activityBatchCount(suggestedCount),
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton.tonal(
            onPressed: () {
              AppHaptics.success();
              context.read<TripDetailBloc>().add(
                BatchValidateActivitiesFromDetail(activityIds: suggestedIds),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.activityBatchValidated),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.activityValidateAll,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              ActivitiesRoute(
                tripId: tripId,
                role: isOwner ? 'OWNER' : 'VIEWER',
                isCompleted: isCompleted,
              ).push(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.activityReviewOneByOne,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day Chip Row (with DragTarget) ───────────────────────────────────────────

class _DayChipRow extends StatelessWidget {
  final int totalDays;
  final int selectedIndex;
  final DateTime tripStartDate;
  final int? currentDay;
  final void Function(Activity activity, int dayIndex) onActivityDrop;

  const _DayChipRow({
    required this.totalDays,
    required this.selectedIndex,
    required this.tripStartDate,
    this.currentDay,
    required this.onActivityDrop,
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

          return DragTarget<Activity>(
            onWillAcceptWithDetails: (details) {
              final activityDate = details.data.date;
              final chipDate = DateTime(date.year, date.month, date.day);
              final actDate = DateTime(
                activityDate.year,
                activityDate.month,
                activityDate.day,
              );
              return actDate != chipDate;
            },
            onAcceptWithDetails: (details) {
              onActivityDrop(details.data, i);
            },
            builder: (ctx, candidateData, rejectedData) {
              final isHighlighted = candidateData.isNotEmpty;

              return GestureDetector(
                onTap: () {
                  AppHaptics.light();
                  context.read<TripDetailBloc>().add(SelectDay(dayIndex: i));
                },
                child: AnimatedContainer(
                  duration: AppAnimations.microInteraction,
                  curve: AppAnimations.standardCurve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: AppRadius.large16,
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isHighlighted
                                ? AppColors.primary
                                : theme.colorScheme.outlineVariant,
                            width: isHighlighted ? 2 : 1,
                          ),
                  ),
                  transform: isHighlighted
                      ? (Matrix4.identity()
                          ..setEntry(0, 0, 1.08)
                          ..setEntry(1, 1, 1.08))
                      : Matrix4.identity(),
                  transformAlignment: Alignment.center,
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
  final int selectedDayIndex;

  const _DayContent({
    super.key,
    required this.dayData,
    required this.isOwner,
    required this.isCompleted,
    required this.tripId,
    required this.trip,
    required this.l10n,
    required this.selectedDayIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (dayData.isEmpty) {
      return _EmptyDayContent(
        isOwner: isOwner,
        isCompleted: isCompleted,
        tripId: tripId,
        l10n: l10n,
        dayNumber: selectedDayIndex + 1,
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
    final parentContext = context;
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
              onEdit: () => _showEditForm(parentContext, activities[i]),
            ),
          ),
        ),
    ];
  }

  void _showEditForm(BuildContext parentContext, Activity activity) {
    final bloc = parentContext.read<TripDetailBloc>();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ActivityForm(
              tripId: tripId,
              activity: activity,
              onSave: (data) {
                Navigator.of(parentContext).pop();
                bloc.add(
                  UpdateActivityFromDetail(activityId: activity.id, data: data),
                );
              },
            ),
          ],
        ),
      ),
    );
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

// ── Empty Day Content (with AI suggestions) ──────────────────────────────────

class _EmptyDayContent extends StatelessWidget {
  final bool isOwner;
  final bool isCompleted;
  final String tripId;
  final AppLocalizations l10n;
  final int dayNumber; // 1-based

  const _EmptyDayContent({
    required this.isOwner,
    required this.isCompleted,
    required this.tripId,
    required this.l10n,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripDetailBloc, TripDetailState>(
      buildWhen: (prev, curr) {
        if (prev is TripDetailLoaded && curr is TripDetailLoaded) {
          return prev.suggestingForDay != curr.suggestingForDay ||
              prev.daySuggestions != curr.daySuggestions ||
              prev.suggestionsForDay != curr.suggestionsForDay;
        }
        return false;
      },
      builder: (context, state) {
        if (state is! TripDetailLoaded) {
          return const SizedBox.shrink();
        }

        final isSuggesting = state.suggestingForDay == dayNumber;
        final hasSuggestions =
            state.suggestionsForDay == dayNumber &&
            state.daySuggestions != null &&
            state.daySuggestions!.isNotEmpty;

        // Loading shimmer
        if (isSuggesting) {
          return _ShimmerPlaceholder();
        }

        // Show inline suggestions
        if (hasSuggestions) {
          return _InlineSuggestions(
            suggestions: state.daySuggestions!,
            tripId: tripId,
            dayNumber: dayNumber,
            l10n: l10n,
            tripStartDate: state.trip.startDate,
          );
        }

        // Default empty state with CTAs
        return ElegantEmptyState(
          icon: Icons.event_outlined,
          title: l10n.timelineEmptyDayTitle,
          subtitle: l10n.timelineEmptyDaySubtitle,
          ctaLabel: isOwner && !isCompleted
              ? l10n.timelineGetSuggestions
              : null,
          ctaIcon: isOwner && !isCompleted ? Icons.auto_awesome : null,
          onCta: isOwner && !isCompleted
              ? () {
                  context.read<TripDetailBloc>().add(
                    SuggestActivitiesForDay(dayNumber: dayNumber),
                  );
                }
              : null,
          secondaryCtaLabel: isOwner && !isCompleted
              ? l10n.addActivityManually
              : null,
          onSecondaryCta: isOwner && !isCompleted
              ? () {
                  ActivitiesRoute(
                    tripId: tripId,
                    isCompleted: isCompleted,
                  ).push(context);
                }
              : null,
        );
      },
    );
  }
}

// ── Shimmer Placeholder ──────────────────────────────────────────────────────

class _ShimmerPlaceholder extends StatefulWidget {
  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity =
            0.3 + 0.4 * (0.5 + 0.5 * (_controller.value * 2 - 1).abs());
        return Column(
          children: List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: AppRadius.large16,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Inline Suggestions ───────────────────────────────────────────────────────

class _InlineSuggestions extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final String tripId;
  final int dayNumber;
  final AppLocalizations l10n;
  final DateTime? tripStartDate;

  const _InlineSuggestions({
    required this.suggestions,
    required this.tripId,
    required this.dayNumber,
    required this.l10n,
    this.tripStartDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.timelineSuggestionsForDay,
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
        for (final suggestion in suggestions)
          _SuggestionCard(
            suggestion: suggestion,
            tripId: tripId,
            dayNumber: dayNumber,
            l10n: l10n,
            tripStartDate: tripStartDate,
          ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final String tripId;
  final int dayNumber;
  final AppLocalizations l10n;
  final DateTime? tripStartDate;

  const _SuggestionCard({
    required this.suggestion,
    required this.tripId,
    required this.dayNumber,
    required this.l10n,
    this.tripStartDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = suggestion['title'] as String? ?? '';
    final description = suggestion['description'] as String? ?? '';
    final cat = suggestion['category'] as String? ?? 'OTHER';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: AppRadius.large16,
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                AppHaptics.light();
                final date = tripStartDate != null
                    ? tripStartDate!.add(Duration(days: dayNumber - 1))
                    : DateTime.now();
                final dateStr = DateFormat('yyyy-MM-dd').format(date);

                final data = <String, dynamic>{
                  'title': title,
                  'date': dateStr,
                  'category': cat,
                  'validationStatus': 'SUGGESTED',
                };
                if (description.isNotEmpty) data['description'] = description;
                if (suggestion['location'] != null) {
                  data['location'] = suggestion['location'];
                }
                if (suggestion['estimated_cost'] != null) {
                  data['estimatedCost'] = suggestion['estimated_cost'];
                }
                if (suggestion['time_of_day'] != null) {
                  final tod = suggestion['time_of_day'] as String;
                  if (tod == 'morning') data['startTime'] = '09:00';
                  if (tod == 'afternoon') data['startTime'] = '14:00';
                  if (tod == 'evening') data['startTime'] = '19:00';
                }

                context.read<TripDetailBloc>().add(
                  CreateActivityFromDetail(data: data),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.primary,
              tooltip: l10n.timelineAddSuggestion,
            ),
          ],
        ),
      ),
    );
  }
}
