import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Horizontal day chips J1…Jn for active trip home (v3): past + check, today +
/// gradient + pulse dot, future discreet; selection ring when viewing a day.
class ActiveTripDayNavigator extends StatefulWidget {
  const ActiveTripDayNavigator({
    super.key,
    required this.totalDays,
    required this.selectedDayIndex0,
    required this.tripStartDate,
    required this.calendarTodayIndex0,
    required this.onDaySelected,
  });

  final int totalDays;
  final int selectedDayIndex0;
  final DateTime tripStartDate;

  /// Null if "today" is outside the trip range.
  final int? calendarTodayIndex0;
  final ValueChanged<int> onDaySelected;

  @override
  State<ActiveTripDayNavigator> createState() => _ActiveTripDayNavigatorState();
}

class _ActiveTripDayNavigatorState extends State<ActiveTripDayNavigator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseOpacity;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseOpacity = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant ActiveTripDayNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDayIndex0 != widget.selectedDayIndex0) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final itemWidth = 56.0 + AppSpacing.space8;
    final offset = (widget.selectedDayIndex0 * itemWidth - 80).clamp(
      0.0,
      double.infinity,
    );
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat(
      'd MMM',
      Localizations.localeOf(context).toString(),
    );
    final start = DateTime(
      widget.tripStartDate.year,
      widget.tripStartDate.month,
      widget.tripStartDate.day,
    );

    return SizedBox(
      height: 72,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.totalDays,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space8),
        itemBuilder: (context, i) {
          final date = start.add(Duration(days: i));
          final ct = widget.calendarTodayIndex0;
          final isCalendarToday = ct != null && i == ct;
          final isSelected = i == widget.selectedDayIndex0;
          final isPast = ct != null && i < ct;
          final isFuture = ct != null && i > ct;

          return GestureDetector(
            onTap: () {
              AppHaptics.light();
              widget.onDaySelected(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCalendarToday
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: PersonalizationColors.accentGradient,
                      )
                    : null,
                color: isCalendarToday ? null : theme.colorScheme.surface,
                border: Border.all(
                  color: isSelected && !isCalendarToday
                      ? ColorName.primary
                      : isFuture || (!isPast && !isCalendarToday && ct == null)
                      ? theme.colorScheme.outlineVariant
                      : isPast
                      ? theme.colorScheme.outline.withValues(alpha: 0.35)
                      : theme.colorScheme.outlineVariant,
                  width: isSelected && !isCalendarToday ? 2 : 1,
                ),
                boxShadow: isCalendarToday
                    ? [
                        BoxShadow(
                          color: ColorName.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'J${i + 1}',
                        style: TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isCalendarToday
                              ? Colors.white
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: isPast ? 0.55 : 1,
                                ),
                        ),
                      ),
                      Text(
                        dateFmt.format(date),
                        style: TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: isCalendarToday
                              ? Colors.white.withValues(alpha: 0.9)
                              : theme.colorScheme.outline.withValues(
                                  alpha: isPast ? 0.5 : 1,
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (isPast && !isCalendarToday)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: ColorName.secondary.withValues(alpha: 0.85),
                      ),
                    ),
                  if (isCalendarToday)
                    Positioned(
                      bottom: -6,
                      child: AnimatedBuilder(
                        animation: _pulseOpacity,
                        builder: (context, child) => Opacity(
                          opacity: _pulseOpacity.value,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x40000000),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
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
