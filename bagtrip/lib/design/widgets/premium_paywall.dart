import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/components/adaptive/adaptive_button.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/subscription/bloc/subscription_bloc.dart';
import 'package:bagtrip/subscription/premium_checkout.dart';
import 'package:bagtrip/subscription/premium_pricing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Premium paywall — designed as an *invitation*, not a wall.
///
/// Single feature on screen at a time (swipeable [PageView]) with restrained
/// typography and a single neutral CTA. Price shown once, in subdued style,
/// not shouted.
///
/// 2026 UX upgrade: the CTA drives the **native Stripe PaymentSheet** —
/// Apple Pay, Google Pay and cards in a sheet sliding up from the bottom.
/// The user never leaves the app, and 3DS is handled in-sheet.
class PremiumPaywall extends StatefulWidget {
  const PremiumPaywall({super.key});

  @override
  State<PremiumPaywall> createState() => _PremiumPaywallState();

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Forward both blocs into the sheet so the upgrade callback can
      // dispatch UserRefresh + LoadSubscription on success.
      builder: (sheetCtx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AuthBloc>()),
          BlocProvider.value(value: context.read<SubscriptionBloc>()),
        ],
        child: const PremiumPaywall(),
      ),
    );
  }
}

class _PremiumPaywallState extends State<PremiumPaywall> {
  final _pageController = PageController();

  bool _isLoading = false;
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleUpgrade() async {
    HapticFeedback.mediumImpact();
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);
    final ok = await PremiumCheckout.run(context);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      // Sheet pops *after* PremiumCheckout has shown the success toast on
      // the parent ScaffoldMessenger — the user lands back on the page
      // they triggered the paywall from, gate already lifted.
      navigator.pop();
    }
  }

  /// Surface an error on the paywall's parent ScaffoldMessenger.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final features = <_PaywallFeature>[
      _PaywallFeature(
        icon: Icons.auto_awesome_outlined,
        title: l10n.premiumFeaturePageAiTitle,
        body: l10n.premiumFeaturePageAiBody,
      ),
      _PaywallFeature(
        icon: Icons.group_outlined,
        title: l10n.premiumFeaturePageViewersTitle,
        body: l10n.premiumFeaturePageViewersBody,
      ),
      _PaywallFeature(
        icon: Icons.notifications_none_rounded,
        title: l10n.premiumFeaturePageOfflineTitle,
        body: l10n.premiumFeaturePageOfflineBody,
      ),
      _PaywallFeature(
        icon: Icons.bookmark_border_rounded,
        title: l10n.premiumFeaturePagePostTripTitle,
        body: l10n.premiumFeaturePagePostTripBody,
      ),
    ];

    return Container(
      // 75% height — enough room to breathe, not enough to feel like an app.
      height: mediaQuery.size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.cornerRadius28),
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: AppSpacing.space12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDisabled.withValues(alpha: 0.3),
                    borderRadius: AppRadius.handleBar,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: features.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _pageIndex = i);
                  },
                  itemBuilder: (context, index) =>
                      _FeaturePage(feature: features[index]),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              _PageDots(count: features.length, currentIndex: _pageIndex),
              const SizedBox(height: AppSpacing.space24),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdaptiveButton(
                      label: l10n.premiumCtaTry,
                      onPressed: _isLoading ? null : _handleUpgrade,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    Text(
                      l10n.premiumPriceLabel(PremiumPricing.displayPrice),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(theme.brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      l10n.premiumDisclaimerCancelAnytime,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        color: AppColors.textDisabled,
                      ),
                    ),
                    SizedBox(
                      height: mediaQuery.padding.bottom + AppSpacing.space16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Explicit dismiss — a paywall the user can't refuse without
          // a swipe-down gesture feels coercive. Top-right is where the
          // close affordance lives on iOS / Android sheets alike.
          Positioned(
            top: AppSpacing.space8,
            right: AppSpacing.space8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textSecondaryOf(theme.brightness),
              tooltip: l10n.subscriptionPaywallClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallFeature {
  final IconData icon;
  final String title;
  final String body;
  const _PaywallFeature({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({required this.feature});
  final _PaywallFeature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(feature.icon, size: 56, color: AppColors.primary),
          const SizedBox(height: AppSpacing.space32),
          Text(
            feature.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            feature.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 15,
              height: 1.5,
              color: AppColors.textSecondaryOf(theme.brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.currentIndex});
  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == currentIndex;
        return AnimatedContainer(
          duration: AppAnimationDurations.quick,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          height: 6,
          width: active ? 18 : 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.textDisabled.withValues(alpha: 0.3),
            borderRadius: AppRadius.dot,
          ),
        );
      }),
    );
  }
}
