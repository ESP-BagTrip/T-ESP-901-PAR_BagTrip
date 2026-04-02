import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Inline range calendar for the plan-trip flow (embedded, not a dialog).
class PlanTripRangeCalendar extends StatefulWidget {
  const PlanTripRangeCalendar({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.selectedStart,
    this.selectedEnd,
    required this.onDayTap,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selectedStart;
  final DateTime? selectedEnd;
  final ValueChanged<DateTime> onDayTap;

  @override
  State<PlanTripRangeCalendar> createState() => _PlanTripRangeCalendarState();
}

class _PlanTripRangeCalendarState extends State<PlanTripRangeCalendar> {
  late DateTime _visibleMonth;
  late PageController _pageController;

  int get _monthTotal {
    final a = widget.firstDate;
    final b = widget.lastDate;
    return (b.year - a.year) * 12 + (b.month - a.month) + 1;
  }

  int _pageForMonth(DateTime month) {
    return (month.year - widget.firstDate.year) * 12 +
        (month.month - widget.firstDate.month);
  }

  DateTime _monthFromPage(int page) {
    return DateTime(widget.firstDate.year, widget.firstDate.month + page);
  }

  @override
  void initState() {
    super.initState();
    final anchor = widget.selectedStart ??
        widget.selectedEnd ??
        DateTime.now();
    _visibleMonth = DateTime(anchor.year, anchor.month);
    if (_visibleMonth.isBefore(
      DateTime(widget.firstDate.year, widget.firstDate.month),
    )) {
      _visibleMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    }
    if (_visibleMonth.isAfter(
      DateTime(widget.lastDate.year, widget.lastDate.month),
    )) {
      _visibleMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    }
    final initialPage = _pageForMonth(_visibleMonth);
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goPrev() {
    final prev = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    if (!prev.isBefore(
      DateTime(widget.firstDate.year, widget.firstDate.month),
    )) {
      final page = _pageForMonth(prev);
      _pageController.animateToPage(
        page,
        duration: AppAnimations.wizardTransition,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goNext() {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    if (!next.isAfter(
      DateTime(widget.lastDate.year, widget.lastDate.month),
    )) {
      final page = _pageForMonth(next);
      _pageController.animateToPage(
        page,
        duration: AppAnimations.wizardTransition,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final canPrev = !_visibleMonth.isBefore(
      DateTime(widget.firstDate.year, widget.firstDate.month),
    );
    final canNext = !_visibleMonth.isAfter(
      DateTime(widget.lastDate.year, widget.lastDate.month),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / 7;
        final gridHeight = 6 * cellW + 8;

        return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large20,
        boxShadow: [
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 6),
            spreadRadius: -1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.large20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: AppSpacing.horizontalSpace16.add(
                const EdgeInsets.only(top: 12, bottom: 8),
              ),
              child: Row(
                children: [
                  _CircleChevron(
                    icon: Icons.chevron_left_rounded,
                    enabled: canPrev,
                    onTap: _goPrev,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppAnimations.microInteraction,
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        DateFormat('MMMM yyyy', locale).format(_visibleMonth),
                        key: ValueKey(_visibleMonth),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: PersonalizationColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  _CircleChevron(
                    icon: Icons.chevron_right_rounded,
                    enabled: canNext,
                    onTap: _goNext,
                  ),
                ],
              ),
            ),
            _buildWeekdayRow(locale),
            SizedBox(
              height: gridHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _monthTotal,
                onPageChanged: (i) {
                  setState(() {
                    _visibleMonth = _monthFromPage(i);
                  });
                },
                itemBuilder: (context, index) {
                  return _buildMonthGrid(
                    context,
                    _monthFromPage(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildWeekdayRow(String locale) {
    final first = DateTime(2024);
    final labels = List.generate(7, (i) {
      final d = first.add(Duration(days: i));
      return DateFormat.E(locale).format(d).substring(0, 1).toUpperCase();
    });
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: labels
            .map(
              (l) => Expanded(
                child: Text(
                  l,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorName.secondary.withValues(alpha: 0.65),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context, DateTime monthDate) {
    final s = widget.selectedStart;
    final e = widget.selectedEnd;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / 7;

        final daysInMonth = DateUtils.getDaysInMonth(
          monthDate.year,
          monthDate.month,
        );
        final firstDayOfMonth = DateTime(monthDate.year, monthDate.month);
        final firstWeekdayOffset = firstDayOfMonth.weekday - 1;

        final cells = <Widget>[];
        for (int i = 0; i < firstWeekdayOffset; i++) {
          cells.add(SizedBox(width: cellW, height: cellW));
        }
        for (int day = 1; day <= daysInMonth; day++) {
          final date = DateTime(monthDate.year, monthDate.month, day);
          cells.add(
            _DayCell(
              day: day,
              date: date,
              cellSize: cellW,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              selectedStart: s,
              selectedEnd: e,
              onTap: () {
                AppHaptics.light();
                widget.onDayTap(date);
              },
            ),
          );
        }
        while (cells.length % 7 != 0) {
          cells.add(SizedBox(width: cellW, height: cellW));
        }

        final rows = <TableRow>[];
        for (int r = 0; r < cells.length / 7; r++) {
          rows.add(
            TableRow(
              children: [
                for (int c = 0; c < 7; c++)
                  cells[r * 7 + c],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Table(
            defaultColumnWidth: FixedColumnWidth(cellW),
            children: rows,
          ),
        );
      },
    );
  }
}

class _CircleChevron extends StatelessWidget {
  const _CircleChevron({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? ColorName.primaryLight.withValues(alpha: 0.6)
                : ColorName.primary.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled
                ? ColorName.secondary.withValues(alpha: 0.85)
                : ColorName.hint,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.date,
    required this.cellSize,
    required this.firstDate,
    required this.lastDate,
    required this.selectedStart,
    required this.selectedEnd,
    required this.onTap,
  });

  final int day;
  final DateTime date;
  final double cellSize;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selectedStart;
  final DateTime? selectedEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateOnly = DateUtils.dateOnly(date);
    final firstOnly = DateUtils.dateOnly(firstDate);
    final lastOnly = DateUtils.dateOnly(lastDate);
    final isDisabled =
        dateOnly.isBefore(firstOnly) || dateOnly.isAfter(lastOnly);

    final s = selectedStart != null ? DateUtils.dateOnly(selectedStart!) : null;
    final e = selectedEnd != null ? DateUtils.dateOnly(selectedEnd!) : null;

    final isStart = s != null && DateUtils.isSameDay(date, s);
    final isEnd = e != null && DateUtils.isSameDay(date, e);
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    bool inBetween = false;
    if (s != null && e != null) {
      inBetween =
          dateOnly.isAfter(s) && dateOnly.isBefore(e);
    }

    final showCircle = isStart || isEnd;
    final diameter = (cellSize * 0.72).clamp(28.0, 40.0);

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: SizedBox(
        height: cellSize,
        width: cellSize,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            if (inBetween)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorName.secondary.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
            if (showCircle)
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ColorName.primary, ColorName.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ColorName.secondary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ColorName.surface,
                  ),
                ),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 15,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isDisabled
                          ? ColorName.hint
                          : (inBetween
                                ? ColorName.primaryTrueDark
                                : (isToday
                                      ? ColorName.primary
                                      : ColorName.primaryTrueDark)),
                    ),
                  ),
                  if (isToday && !showCircle && !inBetween)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: ColorName.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
