import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/activity_tile.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Itinerary tab: day chips on top, [ActivityTile] list for the selected
/// day below. Tap on a tile routes to the full `/activities` page for edit
/// (which handles its own bloc). The day selector dispatches [SelectDay]
/// onto [TripDetailBloc].
class ItineraryPanel extends StatelessWidget {
  const ItineraryPanel({
    super.key,
    required this.tripId,
    required this.activities,
    required this.totalDays,
    required this.selectedDayIndex,
    required this.canEdit,
    required this.isCompleted,
    required this.role,
  });

  final String tripId;
  final List<Activity> activities;
  final int totalDays;
  final int selectedDayIndex;
  final bool canEdit;
  final bool isCompleted;
  final String role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeTotal = totalDays > 0 ? totalDays : 1;
    final safeIndex = selectedDayIndex.clamp(0, safeTotal - 1);
    final grouped = _groupByDay(safeTotal);
    final dayItems = safeIndex < grouped.length
        ? grouped[safeIndex]
        : <Activity>[];

    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ElegantEmptyState(
          icon: Icons.hiking_rounded,
          title: l10n.emptyActivitiesTitle,
          subtitle: canEdit ? l10n.emptyActivitiesSubtitle : null,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space24,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        if (safeTotal > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(safeTotal, (index) {
                final active = index == safeIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => context.read<TripDetailBloc>().add(
                      SelectDay(dayIndex: index),
                    ),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? ColorName.primaryDark
                            : ColorName.surface,
                      ),
                      child: Text(
                        'J${index + 1}',
                        style: TextStyle(
                          fontFamily: FontFamily.dMSerifDisplay,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: active ? ColorName.surface : ColorName.hint,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: AppSpacing.space16),
        if (dayItems.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space24),
            child: Center(
              child: Text(
                l10n.noActivitiesThisDay,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  color: ColorName.hint,
                ),
              ),
            ),
          )
        else
          ...dayItems.map(
            (activity) => ActivityTile(
              title: activity.title,
              description: activity.description ?? '',
              category: _categoryLabel(activity.category),
              onTap: canEdit ? () => _openActivities(context) : null,
            ),
          ),
      ],
    );
  }

  List<List<Activity>> _groupByDay(int safeTotal) {
    final groups = List<List<Activity>>.generate(safeTotal, (_) => []);
    final sorted = [...activities]..sort((a, b) => a.date.compareTo(b.date));
    for (final activity in sorted) {
      final day = _dayIndexFor(activity, safeTotal);
      groups[day].add(activity);
    }
    return groups;
  }

  int _dayIndexFor(Activity activity, int safeTotal) {
    if (activities.isEmpty) return 0;
    final earliest = activities
        .map((a) => a.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final base = DateTime(earliest.year, earliest.month, earliest.day);
    final current = DateTime(
      activity.date.year,
      activity.date.month,
      activity.date.day,
    );
    return current.difference(base).inDays.clamp(0, safeTotal - 1);
  }

  String _categoryLabel(ActivityCategory category) => switch (category) {
    ActivityCategory.culture => 'CULTURE',
    ActivityCategory.nature => 'NATURE',
    ActivityCategory.food => 'FOOD',
    ActivityCategory.sport => 'SPORT',
    ActivityCategory.shopping => 'SHOP',
    ActivityCategory.nightlife => 'NIGHT',
    ActivityCategory.relaxation => 'RELAX',
    ActivityCategory.other => 'ACT',
  };

  void _openActivities(BuildContext context) {
    ActivitiesRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
    ).push(context);
  }
}
