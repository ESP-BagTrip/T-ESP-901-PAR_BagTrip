import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/widgets/home_date_field.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class HomeDateBlock extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const HomeDateBlock({
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
          color: const Color(0xFFF7F9FC),
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
            HomeDateField(
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
