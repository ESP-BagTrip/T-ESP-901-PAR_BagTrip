import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date card for recap/summary screens: calendar icon, label, and either
/// "Choisir" / "Sélectionner" when empty or formatted date when set.
class SummaryDateCard extends StatelessWidget {
  const SummaryDateCard({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayDate = date != null ? DateFormat('EEE d').format(date!) : null;
    final monthYear = date != null
        ? DateFormat('MMMM yyyy').format(date!)
        : null;

    const dateCardRadius = BorderRadius.all(Radius.circular(48));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: dateCardRadius,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ColorName.surface,
            borderRadius: dateCardRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: ColorName.hint,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ColorName.hint,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (dayDate != null) ...[
                Text(
                  dayDate,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColorName.primaryTrueDark,
                  ),
                ),
                if (monthYear != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    monthYear,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 13,
                      color: ColorName.hint,
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  l10n.recapDateChoose,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColorName.primaryTrueDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.recapDateSelectHint,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    color: ColorName.hint,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
