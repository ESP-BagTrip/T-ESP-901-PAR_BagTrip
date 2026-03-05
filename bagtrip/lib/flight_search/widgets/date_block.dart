import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/flight_search/widgets/date_field.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class DateBlock extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const DateBlock({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorName.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: ColorName.secondary,
                fontWeight: FontWeight.w700,
                fontFamily: FontFamily.b612,
              ),
            ),
            const SizedBox(height: 8),
            DateField(
              hint: AppLocalizations.of(context)!.dateFormatHint,
              value: date,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
