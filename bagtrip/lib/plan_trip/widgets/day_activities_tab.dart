import 'dart:math' as math;

import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class DayActivitiesTab extends StatefulWidget {
  const DayActivitiesTab({
    super.key,
    required this.dayProgram,
    required this.dayDescriptions,
    required this.dayCategories,
    required this.durationDays,
  });

  final List<String> dayProgram;
  final List<String> dayDescriptions;
  final List<String> dayCategories;
  final int durationDays;

  @override
  State<DayActivitiesTab> createState() => _DayActivitiesTabState();
}

class _DayActivitiesTabState extends State<DayActivitiesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.durationDays, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<List<int>> _groupByDay() {
    final perDay = (widget.dayProgram.length / widget.durationDays)
        .ceil()
        .clamp(1, widget.dayProgram.length);
    final groups = <List<int>>[];
    for (var d = 0; d < widget.durationDays; d++) {
      final start = d * perDay;
      final end = math.min(start + perDay, widget.dayProgram.length);
      if (start < widget.dayProgram.length) {
        groups.add(List.generate(end - start, (i) => start + i));
      } else {
        groups.add([]);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = _groupByDay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: PersonalizationColors.textSecondary,
          labelStyle: const TextStyle(
            fontFamily: FontFamily.b612,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: FontFamily.b612,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          indicator: const BoxDecoration(
            gradient: LinearGradient(
              colors: PersonalizationColors.accentGradient,
            ),
            borderRadius: AppRadius.pill,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
          ),
          tabs: List.generate(
            widget.durationDays,
            (i) => Tab(text: '${l10n.summaryDayPrefix}${i + 1}', height: 36),
          ),
        ),
        const SizedBox(height: AppSpacing.space12),
        SizedBox(
          height: _estimateTabViewHeight(groups),
          child: TabBarView(
            controller: _tabController,
            children: List.generate(widget.durationDays, (dayIndex) {
              final indices = dayIndex < groups.length
                  ? groups[dayIndex]
                  : <int>[];
              if (indices.isEmpty) {
                return Center(
                  child: Text(
                    l10n.reviewNoActivities,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      color: PersonalizationColors.textTertiary,
                    ),
                  ),
                );
              }
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: indices.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.space8),
                itemBuilder: (context, i) {
                  final idx = indices[i];
                  final title = idx < widget.dayProgram.length
                      ? widget.dayProgram[idx]
                      : '';
                  final desc = idx < widget.dayDescriptions.length
                      ? widget.dayDescriptions[idx]
                      : '';
                  final cat = idx < widget.dayCategories.length
                      ? widget.dayCategories[idx]
                      : '';
                  return StaggeredFadeIn(
                    index: i,
                    child: _ActivityCard(
                      title: title,
                      description: desc,
                      category: cat,
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  double _estimateTabViewHeight(List<List<int>> groups) {
    final maxItems = groups.fold<int>(0, (prev, g) => math.max(prev, g.length));
    // Each card ~80px + 8px separator
    return math.max((maxItems * 88.0) + 16, 80);
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.description,
    required this.category,
  });

  final String title;
  final String description;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.allEdgeInsetSpace12,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.medium8,
        border: Border.all(color: PersonalizationColors.cardBorderUnselected),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _categoryIcon(category),
            size: 20,
            color: PersonalizationColors.accentBlue,
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: PersonalizationColors.textPrimary,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      color: PersonalizationColors.textTertiary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.space8),
            _CategoryChip(category: category),
          ],
        ],
      ),
    );
  }

  static IconData _categoryIcon(String cat) => switch (cat.toUpperCase()) {
    'CULTURE' => Icons.museum_rounded,
    'CUISINE' => Icons.restaurant_rounded,
    'NATURE' => Icons.park_rounded,
    'SPORT' => Icons.fitness_center_rounded,
    _ => Icons.explore_rounded,
  };
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _chipColor(category),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontFamily: FontFamily.b612,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: PersonalizationColors.textSecondary,
        ),
      ),
    );
  }

  static Color _chipColor(String cat) => switch (cat.toUpperCase()) {
    'CULTURE' => AppColors.categoryFlight,
    'CUISINE' => AppColors.categoryFood,
    'NATURE' => AppColors.categoryActivity,
    'SPORT' => AppColors.categoryTransport,
    _ => AppColors.categoryOther,
  };
}
