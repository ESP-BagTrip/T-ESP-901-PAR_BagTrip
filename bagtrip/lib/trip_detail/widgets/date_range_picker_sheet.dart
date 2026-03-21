import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a platform-appropriate date range picker.
///
/// - **Android**: native Material `showDateRangePicker`.
/// - **iOS**: bottom sheet with two `CupertinoDatePicker` wheels.
Future<DateTimeRange?> showTripDateRangePicker({
  required BuildContext context,
  required DateTime? currentStart,
  required DateTime? currentEnd,
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (!AdaptivePlatform.isIOS) {
    return showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 3)),
      initialDateRange: (currentStart != null && currentEnd != null)
          ? DateTimeRange(start: currentStart, end: currentEnd)
          : null,
    );
  }

  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _IosDateRangePickerSheet(
      currentStart: currentStart ?? today,
      currentEnd: currentEnd ?? today.add(const Duration(days: 7)),
      firstDate: today,
    ),
  );
}

class _IosDateRangePickerSheet extends StatefulWidget {
  final DateTime currentStart;
  final DateTime currentEnd;
  final DateTime firstDate;

  const _IosDateRangePickerSheet({
    required this.currentStart,
    required this.currentEnd,
    required this.firstDate,
  });

  @override
  State<_IosDateRangePickerSheet> createState() =>
      _IosDateRangePickerSheetState();
}

class _IosDateRangePickerSheetState extends State<_IosDateRangePickerSheet> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.currentStart;
    _end = widget.currentEnd;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
          const SizedBox(height: AppSpacing.space16),
          Text(
            l10n.editTripDates,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorName.primaryTrueDark,
            ),
          ),
          const SizedBox(height: AppSpacing.space24),

          // Start date
          Padding(
            padding: AppSpacing.horizontalSpace24,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.editTripStartDate,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  color: ColorName.textMutedLight,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 160,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _start,
              minimumDate: widget.firstDate,
              maximumDate: widget.firstDate.add(const Duration(days: 365 * 3)),
              onDateTimeChanged: (date) {
                setState(() {
                  _start = date;
                  if (_end.isBefore(_start)) {
                    _end = _start;
                  }
                });
              },
            ),
          ),

          const SizedBox(height: AppSpacing.space24),

          // End date
          Padding(
            padding: AppSpacing.horizontalSpace24,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.editTripEndDate,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  color: ColorName.textMutedLight,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 160,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _end,
              minimumDate: _start,
              maximumDate: widget.firstDate.add(const Duration(days: 365 * 3)),
              onDateTimeChanged: (date) {
                setState(() {
                  _end = date;
                });
              },
            ),
          ),

          const SizedBox(height: AppSpacing.space24),

          // Save button
          Padding(
            padding: AppSpacing.horizontalSpace24,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(DateTimeRange(start: _start, end: _end));
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.saveButton),
              ),
            ),
          ),

          const SafeArea(
            top: false,
            child: SizedBox(height: AppSpacing.space16),
          ),
        ],
      ),
    );
  }
}
