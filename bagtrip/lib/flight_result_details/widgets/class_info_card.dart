import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ClassInfoCard extends StatelessWidget {
  final String bookingClass;
  final String cabinClass;
  final String fareBasis;

  const ClassInfoCard({
    super.key,
    required this.bookingClass,
    required this.cabinClass,
    required this.fareBasis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
        boxShadow: [
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      padding: AppSpacing.allEdgeInsetSpace16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                color: ColorName.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.classAndConditions,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: ColorName.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info Rows
          _buildInfoRow(
            AppLocalizations.of(context)!.bookingClass,
            bookingClass,
            ColorName.secondary,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            AppLocalizations.of(context)!.cabin,
            cabinClass,
            ColorName.secondary,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            AppLocalizations.of(context)!.fareBasis,
            fareBasis,
            ColorName.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 14,
            color: ColorName.primary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
