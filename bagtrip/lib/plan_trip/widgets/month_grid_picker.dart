import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 4×3 month grid starting from the current month, rolling 12 months.
class MonthGridPicker extends StatelessWidget {
  final int? selectedMonth;
  final int? selectedYear;
  final void Function(int month, int year) onMonthSelected;

  const MonthGridPicker({
    super.key,
    this.selectedMonth,
    this.selectedYear,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final months = List.generate(12, (i) => DateTime(now.year, now.month + i));

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.space8,
      crossAxisSpacing: AppSpacing.space8,
      childAspectRatio: 2.4,
      children: months.map((m) {
        final isPast =
            m.year < now.year || (m.year == now.year && m.month < now.month);
        final isSelected = selectedMonth == m.month && selectedYear == m.year;
        final label = DateFormat('MMM', locale).format(m);

        return GestureDetector(
          onTap: isPast
              ? null
              : () {
                  AppHaptics.light();
                  onMonthSelected(m.month, m.year);
                },
          child: AnimatedContainer(
            duration: AppAnimations.microInteraction,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? ColorName.primaryLight : ColorName.surface,
              borderRadius: AppRadius.large16,
              border: Border.all(
                color: isSelected
                    ? ColorName.primary
                    : ColorName.primarySoftLight,
              ),
            ),
            child: Text(
              '$label\n${m.year}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                height: 1.3,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isPast
                    ? ColorName.hint
                    : isSelected
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
