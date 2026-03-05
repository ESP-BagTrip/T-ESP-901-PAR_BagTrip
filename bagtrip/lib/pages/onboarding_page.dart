import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/primary_button.dart';
import 'package:bagtrip/gen/assets.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/service/onboarding_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Onboarding screen shown once after splash for unauthenticated users.
/// Displays app value proposition and navigates to login on "Commencer" or
/// "Passer l'introduction".
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    await OnboardingStorage().setOnboardingSeen();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PersonalizationColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.allEdgeInsetSpace24,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.space24),
                _buildIllustration(),
                const SizedBox(height: AppSpacing.space24),
                Text(
                  l10n.onboardingTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTrueDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  l10n.onboardingSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                _buildFeatureCard(context, l10n),
                const SizedBox(height: AppSpacing.space32),
                PrimaryButton(
                  label: l10n.onboardingCtaButton,
                  onPressed: () => _completeOnboarding(context),
                ),
                const SizedBox(height: AppSpacing.space16),
                TextButton(
                  onPressed: () => _completeOnboarding(context),
                  child: Text(
                    l10n.onboardingSkip,
                    style: const TextStyle(color: AppColors.textMutedLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      height: 120,
      child: Center(child: Assets.images.appIcon.svg(width: 300, height: 300)),
    );
  }

  Widget _buildFeatureCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: AppSpacing.allEdgeInsetSpace24,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large16,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _FeatureRow(
            icon: Icons.calendar_today_outlined,
            iconBackgroundColor: AppColors.warningLight,
            iconColor: AppColors.warning,
            title: l10n.onboardingFeature1Title,
            description: l10n.onboardingFeature1Desc,
          ),
          const SizedBox(height: AppSpacing.space24),
          _FeatureRow(
            icon: Icons.auto_awesome,
            iconBackgroundColor: AppColors.infoLight,
            iconColor: AppColors.info,
            title: l10n.onboardingFeature2Title,
            description: l10n.onboardingFeature2Desc,
          ),
          const SizedBox(height: AppSpacing.space24),
          _FeatureRow(
            icon: Icons.smart_toy_outlined,
            iconBackgroundColor: AppColors.secondaryLight,
            iconColor: AppColors.secondary,
            title: l10n.onboardingFeature3Title,
            description: l10n.onboardingFeature3Desc,
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final String title;
  final String description;

  static double _descriptionHeight(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final fontSize = style?.fontSize ?? 14.0;
    final height = style?.height ?? 1.2;
    return fontSize * height * 3;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: AppSpacing.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              SizedBox(
                height: _FeatureRow._descriptionHeight(context),
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
