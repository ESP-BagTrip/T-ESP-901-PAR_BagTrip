import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/planifier/widgets/planifier_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Second step of manual trip planning: choose transport (flight, other, or skip).
/// "Oui, chercher un vol" navigates to flight search; other cards are UI only for now.
class PlanifierManualTransportPage extends StatelessWidget {
  const PlanifierManualTransportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: PersonalizationColors.gradientStart,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.transportTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: PersonalizationColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: PersonalizationColors.gradientStart,
        foregroundColor: PersonalizationColors.textPrimary,
      ),
      body: SafeArea(
        left: false,
        right: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            PlanifierCard(
              icon: _buildIconContainer(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.medium8,
                ),
                icon: Icons.flight_rounded,
              ),
              title: l10n.transportOptionFlightTitle,
              description: l10n.transportOptionFlightSubtitle,
              onTap:
                  () => context.push('/trips/planifier/manual/flight-search'),
            ),
            const SizedBox(height: AppSpacing.space16),
            PlanifierCard(
              icon: _buildIconContainer(
                decoration: BoxDecoration(
                  color: AppColors.textMutedLight.withValues(alpha: 0.5),
                  borderRadius: AppRadius.medium8,
                ),
                icon: Icons.directions_car_rounded,
                iconColor: AppColors.primaryTrueDark,
              ),
              title: l10n.transportOptionOtherTitle,
              description: l10n.transportOptionOtherSubtitle,
              onTap:
                  () => context.push('/trips/planifier/manual/transport/other'),
            ),
            const SizedBox(height: AppSpacing.space16),
            PlanifierCard(
              icon: _buildIconContainer(
                decoration: BoxDecoration(
                  color: AppColors.textMutedLight.withValues(alpha: 0.4),
                  borderRadius: AppRadius.medium8,
                ),
                icon: Icons.remove_circle_outline_rounded,
                iconColor: AppColors.primaryTrueDark,
              ),
              title: l10n.transportOptionSkipTitle,
              description: l10n.transportOptionSkipSubtitle,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer({
    required BoxDecoration decoration,
    required IconData icon,
    Color? iconColor,
    double size = 48,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: iconColor ?? AppColors.surface,
        size: size * 0.5,
      ),
    );
  }
}
