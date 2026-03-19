import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bagtrip/l10n/app_localizations.dart';

/// Date selection mode for [FlexibleDatePicker].
enum DateMode { exact, month, flexible }

/// 3-mode date picker with segment control.
///
/// Pure design-system component — no BLoC dependency.
class FlexibleDatePicker extends StatelessWidget {
  final DateMode mode;
  final ValueChanged<DateMode> onModeChanged;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime? start, DateTime? end)? onDatesChanged;
  final DateTime? selectedMonth;
  final ValueChanged<DateTime>? onMonthChanged;
  final String? flexibilityLabel;
  final ValueChanged<String>? onFlexibilityChanged;

  const FlexibleDatePicker({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.startDate,
    this.endDate,
    this.onDatesChanged,
    this.selectedMonth,
    this.onMonthChanged,
    this.flexibilityLabel,
    this.onFlexibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Segment control
        _buildSegmentControl(context, l10n),
        const SizedBox(height: AppSpacing.space16),
        // Mode content
        AnimatedSwitcher(
          duration: AppAnimations.wizardTransition,
          child: _buildModeContent(context, l10n),
        ),
      ],
    );
  }

  Widget _buildSegmentControl(BuildContext context, AppLocalizations l10n) {
    final labels = {
      DateMode.exact: l10n.datesModeExact,
      DateMode.month: l10n.datesModeMonth,
      DateMode.flexible: l10n.datesModeFlexible,
    };

    if (AdaptivePlatform.isIOS) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<DateMode>(
          groupValue: mode,
          onValueChanged: (v) {
            if (v != null) {
              AppHaptics.light();
              onModeChanged(v);
            }
          },
          children: {
            for (final entry in labels.entries)
              entry.key: Padding(
                padding: AppSpacing.verticalSpace4,
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                  ),
                ),
              ),
          },
        ),
      );
    }

    return SegmentedButton<DateMode>(
      segments: labels.entries
          .map(
            (e) => ButtonSegment<DateMode>(value: e.key, label: Text(e.value)),
          )
          .toList(),
      selected: {mode},
      onSelectionChanged: (selected) {
        AppHaptics.light();
        onModeChanged(selected.first);
      },
      style: const ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: FontFamily.b612, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildModeContent(BuildContext context, AppLocalizations l10n) {
    switch (mode) {
      case DateMode.exact:
        return _ExactDateContent(
          key: const ValueKey(DateMode.exact),
          startDate: startDate,
          endDate: endDate,
          onDatesChanged: onDatesChanged,
          l10n: l10n,
        );
      case DateMode.month:
        return _MonthContent(
          key: const ValueKey(DateMode.month),
          selectedMonth: selectedMonth,
          onMonthChanged: onMonthChanged,
        );
      case DateMode.flexible:
        return _FlexibleContent(
          key: const ValueKey(DateMode.flexible),
          selectedLabel: flexibilityLabel,
          onChanged: onFlexibilityChanged,
          l10n: l10n,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Exact mode: two date cards
// ---------------------------------------------------------------------------

class _ExactDateContent extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime? start, DateTime? end)? onDatesChanged;
  final AppLocalizations l10n;

  const _ExactDateContent({
    super.key,
    this.startDate,
    this.endDate,
    this.onDatesChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateCard(
            label: l10n.departLabel,
            date: startDate,
            onTap: () => _pick(context),
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: _DateCard(
            label: l10n.returnLabel,
            date: endDate,
            onTap: () => _pick(context),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );
    if (range != null) {
      onDatesChanged?.call(range.start, range.end);
    }
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateCard({required this.label, this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        decoration: BoxDecoration(
          color: ColorName.surface,
          borderRadius: AppRadius.large16,
          border: Border.all(color: ColorName.primarySoftLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ColorName.secondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              date != null ? '${date!.day}/${date!.month}/${date!.year}' : '—',
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ColorName.primaryTrueDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month mode: horizontal scrollable month chips
// ---------------------------------------------------------------------------

class _MonthContent extends StatelessWidget {
  final DateTime? selectedMonth;
  final ValueChanged<DateTime>? onMonthChanged;

  const _MonthContent({super.key, this.selectedMonth, this.onMonthChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(12, (i) => DateTime(now.year, now.month + i));

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space8),
        itemBuilder: (context, index) {
          final m = months[index];
          final isSelected =
              selectedMonth != null &&
              selectedMonth!.year == m.year &&
              selectedMonth!.month == m.month;

          return GestureDetector(
            onTap: () {
              AppHaptics.light();
              onMonthChanged?.call(m);
            },
            child: AnimatedContainer(
              duration: AppAnimations.microInteraction,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space12,
              ),
              decoration: BoxDecoration(
                color: isSelected ? ColorName.primaryLight : ColorName.surface,
                borderRadius: AppRadius.pill,
                border: Border.all(
                  color: isSelected
                      ? ColorName.primary
                      : ColorName.primarySoftLight,
                ),
              ),
              child: Text(
                _monthLabel(m),
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected
                      ? ColorName.primary
                      : ColorName.primaryTrueDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _monthLabel(DateTime d) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[(d.month - 1) % 12]} ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// Flexible mode: text chips
// ---------------------------------------------------------------------------

class _FlexibleContent extends StatelessWidget {
  final String? selectedLabel;
  final ValueChanged<String>? onChanged;
  final AppLocalizations l10n;

  const _FlexibleContent({
    super.key,
    this.selectedLabel,
    this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      l10n.datesFlexibleWhenever,
      l10n.datesFlexibleWeekend,
      l10n.datesFlexibleWeek,
      l10n.datesFlexibleTwoWeeks,
    ];

    return Wrap(
      spacing: AppSpacing.space8,
      runSpacing: AppSpacing.space8,
      children: options.map((label) {
        final isSelected = selectedLabel == label;
        return GestureDetector(
          onTap: () {
            AppHaptics.light();
            onChanged?.call(label);
          },
          child: AnimatedContainer(
            duration: AppAnimations.microInteraction,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space12,
            ),
            decoration: BoxDecoration(
              color: isSelected ? ColorName.primaryLight : ColorName.surface,
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: isSelected
                    ? ColorName.primary
                    : ColorName.primarySoftLight,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected
                    ? ColorName.primary
                    : ColorName.primaryTrueDark,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
