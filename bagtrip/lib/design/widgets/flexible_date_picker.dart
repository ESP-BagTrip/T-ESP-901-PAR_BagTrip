import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/plan_trip_range_calendar.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/models/date_mode.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:bagtrip/plan_trip/widgets/duration_chip_selector.dart';
import 'package:bagtrip/plan_trip/widgets/month_grid_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 3-mode date picker with segment control.
///
/// Pure design-system component — no BLoC dependency.
class FlexibleDatePicker extends StatelessWidget {
  final DateMode mode;
  final ValueChanged<DateMode> onModeChanged;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime? start, DateTime? end)? onDatesChanged;
  final int? selectedMonth;
  final int? selectedYear;
  final void Function(int month, int year)? onMonthSelected;
  final DurationPreset? selectedDuration;
  final ValueChanged<DurationPreset>? onDurationChanged;

  const FlexibleDatePicker({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.startDate,
    this.endDate,
    this.onDatesChanged,
    this.selectedMonth,
    this.selectedYear,
    this.onMonthSelected,
    this.selectedDuration,
    this.onDurationChanged,
  });

  static const _modes = [DateMode.exact, DateMode.month, DateMode.flexible];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSegmentControl(context, l10n),
        const SizedBox(height: AppSpacing.space16),
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

    return Container(
      width: double.infinity,
      padding: AppSpacing.allEdgeInsetSpace4,
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.pill,
        boxShadow: [
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _modes.length; i++) ...[
            if (i > 0) const SizedBox(width: 0),
            Expanded(
              child: _SegmentChip(
                label: labels[_modes[i]]!,
                selected: mode == _modes[i],
                onTap: () {
                  AppHaptics.light();
                  onModeChanged(_modes[i]);
                },
              ),
            ),
          ],
        ],
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
        return MonthGridPicker(
          key: const ValueKey(DateMode.month),
          selectedMonth: selectedMonth,
          selectedYear: selectedYear,
          onMonthSelected: (month, year) => onMonthSelected?.call(month, year),
        );
      case DateMode.flexible:
        return DurationChipSelector(
          key: const ValueKey(DateMode.flexible),
          selected: selectedDuration,
          onSelected: (preset) => onDurationChanged?.call(preset),
        );
    }
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: AnimatedContainer(
          duration: AppAnimations.microInteraction,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? ColorName.secondary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: AppRadius.pill,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? ColorName.primaryDark : ColorName.hint,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exact mode: two date cards + inline calendar
// ---------------------------------------------------------------------------

enum _DateCardFocus { departure, returnDate }

class _ExactDateContent extends StatefulWidget {
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
  State<_ExactDateContent> createState() => _ExactDateContentState();
}

class _ExactDateContentState extends State<_ExactDateContent> {
  DateTime? _localStart;
  DateTime? _localEnd;
  _DateCardFocus _focus = _DateCardFocus.departure;

  @override
  void initState() {
    super.initState();
    _localStart = widget.startDate;
    _localEnd = widget.endDate;
    _syncFocusFromSelection();
  }

  @override
  void didUpdateWidget(covariant _ExactDateContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate) {
      _localStart = widget.startDate;
      _localEnd = widget.endDate;
      _syncFocusFromSelection();
    }
  }

  void _syncFocusFromSelection() {
    if (_localStart != null && _localEnd == null) {
      _focus = _DateCardFocus.returnDate;
    } else if (_localStart == null) {
      _focus = _DateCardFocus.departure;
    }
  }

  void _onDayTap(DateTime date) {
    final dateOnly = DateUtils.dateOnly(date);
    if (_focus == _DateCardFocus.departure) {
      setState(() {
        _localStart = date;
        _localEnd = null;
        _focus = _DateCardFocus.returnDate;
      });
      return;
    }
    if (_localStart == null) {
      setState(() {
        _localStart = date;
        _localEnd = null;
        _focus = _DateCardFocus.returnDate;
      });
      return;
    }
    final startOnly = DateUtils.dateOnly(_localStart!);
    setState(() {
      if (dateOnly.isBefore(startOnly)) {
        _localEnd = _localStart;
        _localStart = date;
      } else {
        _localEnd = date;
      }
    });
    final start = _localStart;
    final end = _localEnd;
    if (start != null && end != null) {
      widget.onDatesChanged?.call(start, end);
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('d MMM yyyy', locale).format(d);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final now = DateTime.now();
    final firstDate = DateUtils.dateOnly(now);
    final lastDate = DateUtils.dateOnly(now.add(const Duration(days: 365)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _DateCard(
                label: l10n.departLabel,
                formattedDate: _formatDate(_localStart),
                placeholder: l10n.datesChooseDatePlaceholder,
                isActive: _focus == _DateCardFocus.departure,
                onTap: () {
                  AppHaptics.light();
                  setState(() {
                    _focus = _DateCardFocus.departure;
                    if (_localEnd != null) {
                      _localEnd = null;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: _DateCard(
                label: l10n.returnLabel,
                formattedDate: _formatDate(_localEnd),
                placeholder: l10n.datesChooseDatePlaceholder,
                isActive: _focus == _DateCardFocus.returnDate,
                onTap: () {
                  AppHaptics.light();
                  setState(() {
                    _focus = _DateCardFocus.returnDate;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space16),
        PlanTripRangeCalendar(
          firstDate: firstDate,
          lastDate: lastDate,
          selectedStart: _localStart,
          selectedEnd: _localEnd,
          onDayTap: _onDayTap,
        ),
      ],
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.formattedDate,
    required this.placeholder,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String formattedDate;
  final String placeholder;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDate = formattedDate.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large16,
        child: AnimatedContainer(
          duration: AppAnimations.microInteraction,
          decoration: BoxDecoration(
            color: ColorName.surface,
            borderRadius: AppRadius.large24,
            border: Border.all(
              color: isActive
                  ? ColorName.secondary.withValues(alpha: 0.45)
                  : ColorName.primarySoftLight,
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: ColorName.secondary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.large24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  Container(
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ColorName.primary, ColorName.secondary],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space16,
                    vertical: AppSpacing.space12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ColorName.secondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      const SizedBox(height: 2),
                      Text(
                        hasDate ? formattedDate : placeholder,
                        style: TextStyle(
                          fontFamily: FontFamily.dMSerifDisplay,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: hasDate
                              ? ColorName.primaryDark
                              : ColorName.hint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
