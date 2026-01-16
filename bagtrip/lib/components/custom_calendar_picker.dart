import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../design/tokens.dart';

class DateRangeResult {
  final DateTime startDate;
  final DateTime? endDate;

  DateRangeResult({required this.startDate, this.endDate});
}

Future<DateRangeResult?> showCustomCalendarPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  bool isRangeSelection = false,
  DateTime? initialEndDate,
}) async {
  return showDialog<DateRangeResult?>(
    context: context,
    builder: (BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final dialogWidth = screenWidth - 32; // 16px padding on each side

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: CustomCalendarPicker(
          initialDate: initialDate,
          initialEndDate: initialEndDate,
          firstDate: firstDate,
          lastDate: lastDate,
          dialogWidth: dialogWidth,
          isRangeSelection: isRangeSelection,
        ),
      );
    },
  );
}

class CustomCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final double dialogWidth;
  final bool isRangeSelection;

  const CustomCalendarPicker({
    super.key,
    required this.initialDate,
    this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
    required this.dialogWidth,
    this.isRangeSelection = false,
  });

  @override
  State<CustomCalendarPicker> createState() => _CustomCalendarPickerState();
}

class _CustomCalendarPickerState extends State<CustomCalendarPicker> {
  late DateTime _currentMonth;
  late DateTime? _selectedStartDate;
  late DateTime? _selectedEndDate;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    if (widget.isRangeSelection) {
      _selectedStartDate = widget.initialDate;
      _selectedEndDate = widget.initialEndDate;
    } else {
      _selectedStartDate = widget.initialDate;
      _selectedEndDate = null;
    }
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);

    // Calculate initial page index
    final initialPage = _getPageIndex(_currentMonth);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(initialPage);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _getPageIndex(DateTime month) {
    return (month.year - widget.firstDate.year) * 12 +
        (month.month - widget.firstDate.month);
  }

  DateTime _getMonthFromPageIndex(int pageIndex) {
    return DateTime(widget.firstDate.year, widget.firstDate.month + pageIndex);
  }

  void _goToPreviousMonth() {
    final newMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    if (!newMonth.isBefore(
      DateTime(widget.firstDate.year, widget.firstDate.month),
    )) {
      setState(() {
        _currentMonth = newMonth;
      });
      final pageIndex = _getPageIndex(_currentMonth);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _goToNextMonth() {
    final newMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (!newMonth.isAfter(
      DateTime(widget.lastDate.year, widget.lastDate.month),
    )) {
      setState(() {
        _currentMonth = newMonth;
      });
      final pageIndex = _getPageIndex(_currentMonth);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _selectDate(DateTime date) {
    if (!widget.isRangeSelection) {
      // Single date selection
      if (mounted) {
        Navigator.of(context).pop(DateRangeResult(startDate: date));
      }
      return;
    }

    // Range selection
    setState(() {
      if (_selectedStartDate == null || _selectedEndDate != null) {
        // Start new selection
        _selectedStartDate = date;
        _selectedEndDate = null;
      } else {
        // Complete the range
        final startDateOnly = DateUtils.dateOnly(_selectedStartDate!);
        final dateOnly = DateUtils.dateOnly(date);

        if (dateOnly.isBefore(startDateOnly)) {
          // If selected date is before start, swap them
          _selectedEndDate = _selectedStartDate;
          _selectedStartDate = date;
        } else if (dateOnly.isAtSameMomentAs(startDateOnly)) {
          // Same date selected, treat as single date
          _selectedEndDate = date;
        } else {
          _selectedEndDate = date;
        }

        // Close dialog when range is complete
        if (mounted && _selectedEndDate != null) {
          Navigator.of(context).pop(
            DateRangeResult(
              startDate: _selectedStartDate!,
              endDate: _selectedEndDate,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalMonths =
        (widget.lastDate.year - widget.firstDate.year) * 12 +
        (widget.lastDate.month - widget.firstDate.month) +
        1;

    // Calculate fixed height for calendar (always 6 rows maximum)
    final cellSize = (widget.dialogWidth - 32) / 7; // 16px padding on each side
    // Each cell has margin of 2px on all sides (4px total vertical per cell)
    // Plus padding vertical of 8px top and bottom = 16px total
    // Add extra space to ensure all 6 rows are fully visible
    final fixedMonthHeight =
        (6 * cellSize) + 32; // Always 6 rows + padding + extra space
    final headerHeight =
        48; // Header height (12px top + 12px bottom + 24px content)
    final weekDaysHeight =
        36; // Week days height (12px top + 12px bottom + 12px text)
    final totalHeight = headerHeight + weekDaysHeight + fixedMonthHeight;

    return Container(
      width: widget.dialogWidth,
      height: totalHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildHeader(),
            _buildWeekDays(),
            Expanded(
              child: SizedBox(
                height: fixedMonthHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: totalMonths,
                  onPageChanged: (index) {
                    setState(() {
                      _currentMonth = _getMonthFromPageIndex(index);
                    });
                  },
                  itemBuilder: (context, index) {
                    final month = _getMonthFromPageIndex(index);
                    return _buildMonth(month);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final locale = Localizations.localeOf(context).toString();
    final monthYearText = DateFormat('MMM yyyy', locale).format(_currentMonth);
    final canGoPrevious =
        !_currentMonth.isBefore(
          DateTime(widget.firstDate.year, widget.firstDate.month),
        );
    final canGoNext =
        !_currentMonth.isAfter(
          DateTime(widget.lastDate.year, widget.lastDate.month),
        );

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375; // iPhone SE width
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final fontSize = isSmallScreen ? 16.0 : 18.0;
    final spacing = isSmallScreen ? 8.0 : 16.0;

    return Container(
      width: double.infinity,
      padding: AppSpacing.allEdgeInsetSpace24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: canGoPrevious ? _goToPreviousMonth : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          canGoPrevious
                              ? ColorName.secondary.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color:
                          canGoPrevious
                              ? ColorName.secondary
                              : Colors.grey.withValues(alpha: 0.3),
                      size: iconSize,
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Flexible(
                  child: Text(
                    monthYearText,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: ColorName.secondary,
                      fontFamily: FontFamily.b612,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing),
                GestureDetector(
                  onTap: canGoNext ? _goToNextMonth : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          canGoNext
                              ? ColorName.secondary.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color:
                          canGoNext
                              ? ColorName.secondary
                              : Colors.grey.withValues(alpha: 0.3),
                      size: iconSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ColorName.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: ColorName.secondary,
                size: iconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    final locale = Localizations.localeOf(context).toString();
    final firstDayOfWeek = DateTime(2024);
    final weekDays = List.generate(7, (index) {
      final date = firstDayOfWeek.add(Duration(days: index));
      final dayName = DateFormat.E(locale).format(date);
      return dayName.substring(0, 1).toUpperCase();
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final cellSize = availableWidth / 7;

          return Table(
            defaultColumnWidth: FixedColumnWidth(cellSize),
            children: [
              TableRow(
                children:
                    weekDays
                        .map(
                          (day) => Text(
                            day,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: ColorName.secondary,
                              fontWeight: FontWeight.w600,
                              fontFamily: FontFamily.b612,
                              fontSize: 14,
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonth(DateTime monthDate) {
    final daysInMonth = DateUtils.getDaysInMonth(
      monthDate.year,
      monthDate.month,
    );
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month);
    final int firstWeekdayOffset = firstDayOfMonth.weekday - 1;

    final List<Widget> dayWidgets = [];

    // Empty slots for previous month
    for (int i = 0; i < firstWeekdayOffset; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Days
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(monthDate.year, monthDate.month, i);
      final dateOnly = DateUtils.dateOnly(date);
      final isDisabled =
          dateOnly.isBefore(DateUtils.dateOnly(widget.firstDate)) ||
          dateOnly.isAfter(DateUtils.dateOnly(widget.lastDate));

      bool isSelected = false;
      bool isInRange = false;
      bool isStartDate = false;
      bool isEndDate = false;

      if (widget.isRangeSelection) {
        if (_selectedStartDate != null) {
          final startDateOnly = DateUtils.dateOnly(_selectedStartDate!);
          isStartDate = DateUtils.isSameDay(date, _selectedStartDate);

          if (_selectedEndDate != null) {
            final endDateOnly = DateUtils.dateOnly(_selectedEndDate!);
            isEndDate = DateUtils.isSameDay(date, _selectedEndDate);
            isSelected = isStartDate || isEndDate;
            isInRange =
                dateOnly.isAfter(startDateOnly) &&
                dateOnly.isBefore(endDateOnly);
          } else {
            isSelected = isStartDate;
          }
        }
      } else {
        isSelected =
            _selectedStartDate != null &&
            DateUtils.isSameDay(date, _selectedStartDate);
      }

      final isToday = DateUtils.isSameDay(date, DateTime.now());

      dayWidgets.add(
        GestureDetector(
          onTap:
              isDisabled
                  ? null
                  : () {
                    _selectDate(date);
                  },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isSelected
                      ? ColorName.primary
                      : (isInRange
                          ? ColorName.primary.withValues(alpha: 0.2)
                          : (isToday
                              ? ColorName.primary.withValues(alpha: 0.1)
                              : Colors.transparent)),
            ),
            alignment: Alignment.center,
            child: Text(
              '$i',
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.white
                        : (isDisabled
                            ? Colors.grey.withValues(alpha: 0.3)
                            : (isToday
                                ? ColorName.primary
                                : ColorName.secondary)),
                fontWeight:
                    isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                fontFamily: FontFamily.b612,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final cellSize = availableWidth / 8;

          return Table(
            defaultColumnWidth: FixedColumnWidth(cellSize),
            children: [
              for (int row = 0; row < (dayWidgets.length / 7).ceil(); row++)
                TableRow(
                  children: [
                    for (int col = 0; col < 7; col++)
                      SizedBox(
                        height: cellSize,
                        child:
                            (row * 7 + col < dayWidgets.length)
                                ? dayWidgets[row * 7 + col]
                                : const SizedBox(),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
