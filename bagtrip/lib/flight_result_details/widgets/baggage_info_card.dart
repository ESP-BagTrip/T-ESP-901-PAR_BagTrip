import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flight_search_result/models/baggage_info.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BaggageInfoCard extends StatelessWidget {
  final BaggageInfo? checkedBags;
  final BaggageInfo? cabinBags;

  const BaggageInfoCard({
    super.key,
    required this.checkedBags,
    required this.cabinBags,
  });

  String _formatBaggage(BuildContext context, BaggageInfo? baggage) {
    if (baggage == null) {
      return AppLocalizations.of(context)!.baggageNotIncluded;
    }
    if (baggage.weight != null) {
      return AppLocalizations.of(context)!.baggageKg(baggage.weight!);
    }
    if (baggage.quantity != null) {
      return AppLocalizations.of(context)!.baggageQuantity(baggage.quantity!);
    }
    return AppLocalizations.of(context)!.baggageNotIncluded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
        boxShadow: AppShadows.card,
      ),
      padding: AppSpacing.allEdgeInsetSpace16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.luggage, color: ColorName.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.baggageIncluded,
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
          // Cabin Baggage
          _buildBaggageRow(
            icon: Icons.work_outline,
            title: AppLocalizations.of(context)!.cabinBag,
            subtitle: _formatBaggage(context, cabinBags),
            subtitleColor: ColorName.secondary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          // Checked Baggage
          _buildBaggageRow(
            icon: Icons.luggage_outlined,
            title: AppLocalizations.of(context)!.checkedBag,
            subtitle: _formatBaggage(context, checkedBags),
            subtitleColor: ColorName.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBaggageRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ColorName.primary, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                color: ColorName.primary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
