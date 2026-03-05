import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/widgets/premium_cta_button.dart';
import 'package:bagtrip/design/widgets/premium_step_indicator.dart';
import 'package:bagtrip/gen/assets.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Welcome screen for personalization: hero, title, subtitle, step indicator, CTA.
class WelcomeStepContent extends StatelessWidget {
  const WelcomeStepContent({
    super.key,
    required this.totalSteps,
    required this.onStart,
    this.onSkip,
  });

  final int totalSteps;
  final VoidCallback onStart;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 16.0 : (width > 600 ? 32.0 : 24.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: width < 360 ? 32 : 48),
        SizedBox(
          height: width < 360 ? 100 : 140,
          child: Center(
            child: Assets.images.appIcon.svg(
              width: width < 360 ? 80 : 120,
              height: width < 360 ? 80 : 120,
            ),
          ),
        ),
        SizedBox(height: width < 360 ? 32 : 48),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            l10n.personalizationWelcomeTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: PersonalizationColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            l10n.personalizationWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: PersonalizationColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        SizedBox(height: width < 360 ? 32 : 40),
        PremiumStepIndicator(current: 1, total: totalSteps),
        SizedBox(height: width < 360 ? 40 : 56),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: PremiumCtaButton(
            label: l10n.personalizationWelcomeCta,
            onPressed: onStart,
          ),
        ),
        if (onSkip != null) ...[
          const SizedBox(height: 20),
          TextButton(
            onPressed: onSkip,
            child: Text(
              l10n.personalizationSkip,
              style: const TextStyle(
                color: PersonalizationColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
