import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/repositories/subscription_repository.dart';
import 'package:bagtrip/subscription/bloc/subscription_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

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
  final _subscriptionRepository = getIt<SubscriptionRepository>();
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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      // 1. Server creates Subscription(default_incomplete) + EphemeralKey.
      debugPrint('[paywall] starting subscription bootstrap');
      final startResult = await _subscriptionRepository.start();
      if (!mounted) return;
      switch (startResult) {
        case Failure(:final error):
          debugPrint('[paywall] /start failed: $error');
          _showError(toUserFriendlyMessage(error, l10n));
          return;
        case Success(:final data):
          debugPrint(
            '[paywall] /start ok — sub=${data.subscriptionId}, '
            'pi=${data.paymentIntentClientSecret.substring(0, 12)}…',
          );
          // 2. Initialise the native PaymentSheet with the trio Stripe needs.
          //    Apple Pay + Google Pay are surfaced automatically when
          //    available on the device — no extra wiring on this side.
          debugPrint('[paywall] initPaymentSheet…');
          await stripe.Stripe.instance.initPaymentSheet(
            paymentSheetParameters: stripe.SetupPaymentSheetParameters(
              merchantDisplayName: 'BagTrip',
              paymentIntentClientSecret: data.paymentIntentClientSecret,
              customerId: data.customer,
              customerEphemeralKeySecret: data.ephemeralKey,
              // Apple Pay only renders when an iOS merchant identifier is
              // configured in Info.plist + Apple Pay capability is enabled
              // in Xcode. Until then keep it off so it doesn't blow up
              // initPaymentSheet on iOS dev builds.
              googlePay: const stripe.PaymentSheetGooglePay(
                merchantCountryCode: 'FR',
                currencyCode: 'EUR',
                testEnv: kDebugMode,
              ),
              style: ThemeMode.system,
            ),
          );
          debugPrint('[paywall] initPaymentSheet ok');
          if (!mounted) return;
          // 3. User pays in-sheet. Throws StripeException on cancel/error;
          //    success means the PaymentIntent is confirmed (3DS included).
          debugPrint('[paywall] presentPaymentSheet…');
          await stripe.Stripe.instance.presentPaymentSheet();
          debugPrint('[paywall] presentPaymentSheet ok');
          if (!mounted) return;
          // 4. Refresh user (webhook flips plan→PREMIUM) and route to the
          //    welcome page. The page itself polls until the webhook lands.
          context.read<AuthBloc>().add(UserRefreshRequested());
          context.read<SubscriptionBloc>().add(LoadSubscription());
          Navigator.of(context).pop(); // close the paywall sheet
          if (!mounted) return;
          const SubscriptionSuccessRoute().go(context);
          return;
      }
    } on stripe.StripeException catch (e, st) {
      // Cancel is a non-event — no toast, just close the loading state.
      if (e.error.code == stripe.FailureCode.Canceled) {
        debugPrint('[paywall] user cancelled the sheet');
        return;
      }
      debugPrint(
        '[paywall] StripeException: code=${e.error.code} '
        'message=${e.error.message} declineCode=${e.error.declineCode}\n$st',
      );
      if (!mounted) return;
      _showError(
        e.error.localizedMessage ?? e.error.message ?? l10n.errorUnknown,
      );
    } catch (e, st) {
      debugPrint('[paywall] unexpected error: $e\n$st');
      if (!mounted) return;
      _showError('${l10n.errorUnknown}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Show an error toast that survives the paywall context. The bottom-sheet
  /// has its own ScaffoldMessenger, so we hop to the root one — otherwise
  /// the snackbar appears *behind* the sheet and the user never sees it.
  void _showError(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    // Fallback to the project's snackbar if the root messenger is unreachable.
    AppSnackBar.showError(context, message: message);
  }

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
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.space12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CalmCtaButton(
                  label: l10n.premiumCtaTry,
                  onPressed: _handleUpgrade,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSpacing.space12),
                Text(
                  l10n.premiumPriceLabel('9,99 €'),
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
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Restrained CTA — single solid colour, no gradient, scale-on-press only.
class _CalmCtaButton extends StatefulWidget {
  const _CalmCtaButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<_CalmCtaButton> createState() => _CalmCtaButtonState();
}

class _CalmCtaButtonState extends State<_CalmCtaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isLoading || widget.onPressed == null;
    return Semantics(
      button: true,
      label: widget.label,
      enabled: !disabled,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: AppAnimationDurations.microInteraction,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: disabled
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : AppColors.primary,
              borderRadius: AppRadius.large20,
            ),
            child: widget.isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
