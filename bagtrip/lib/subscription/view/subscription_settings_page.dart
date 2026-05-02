import 'package:bagtrip/components/adaptive/adaptive_app_bar.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/payment_method_preview.dart';
import 'package:bagtrip/models/subscription_details.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/subscription/bloc/subscription_bloc.dart';
import 'package:bagtrip/subscription/premium_checkout.dart';
import 'package:bagtrip/subscription/premium_pricing.dart';
import 'package:bagtrip/subscription/view/cancel_subscription_sheet.dart';
import 'package:bagtrip/subscription/view/reactivate_subscription_sheet.dart';
import 'package:bagtrip/subscription/view/update_payment_method_sheet.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// "Manage subscription" — the showcase page.
///
/// Inspired by iOS Settings → Apple ID → Subscriptions: large breathing
/// typography, divider-separated sections, no decorative borders. The
/// destructive cancel action is a `ListTile` with red text rather than a
/// solid red button — the copy carries the weight, not the chrome.
class SubscriptionSettingsPage extends StatefulWidget {
  const SubscriptionSettingsPage({super.key});

  @override
  State<SubscriptionSettingsPage> createState() =>
      _SubscriptionSettingsPageState();
}

class _SubscriptionSettingsPageState extends State<SubscriptionSettingsPage> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<SubscriptionBloc>();
    if (!bloc.state.hasData) {
      bloc.add(LoadSubscription());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AdaptiveAppBar.build(
        context: context,
        title: l10n.subscriptionPageTitle,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listenWhen: (prev, curr) =>
            prev.actionInFlight != SubscriptionAction.idle &&
            curr.actionInFlight == SubscriptionAction.idle &&
            curr.error == null,
        listener: (context, state) {
          // Cancel/reactivate succeeded — show subtle toast. The page itself
          // re-fetches automatically via the LoadSubscription dispatch in
          // the bloc, so the badge / actions update without intervention.
        },
        builder: (context, state) {
          if (state.isLoading && !state.hasData) {
            return const _LoadingScaffold();
          }
          if (state.error != null && !state.hasData) {
            return _ErrorView(
              message: toUserFriendlyMessage(state.error!, l10n),
              onRetry: () =>
                  context.read<SubscriptionBloc>().add(LoadSubscription()),
            );
          }
          final details = state.details;
          if (details == null) {
            return const SizedBox.shrink();
          }
          return RefreshIndicator.adaptive(
            onRefresh: () async {
              context.read<SubscriptionBloc>().add(RefreshSubscription());
              // Wait for the next state where loading finishes.
              await context.read<SubscriptionBloc>().stream.firstWhere(
                (s) => !s.isLoading && !s.isRefreshing,
              );
            },
            child: details.isPremium
                ? _PremiumBody(state: state)
                : const _FreeBody(),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium body — the core showcase
// ---------------------------------------------------------------------------

class _PremiumBody extends StatelessWidget {
  const _PremiumBody({required this.state});
  final SubscriptionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final details = state.details!;
    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).languageCode,
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        AppSpacing.space24,
        AppSpacing.space24,
        AppSpacing.space48,
      ),
      children: [
        // Status badge — simple text, no chip with background.
        _StatusBadge(details: details),
        const SizedBox(height: AppSpacing.space32),

        // Payment method card.
        if (details.paymentMethod != null) ...[
          _PaymentMethodCard(method: details.paymentMethod!),
          const SizedBox(height: AppSpacing.space24),
        ],

        // Renewal / expiry summary.
        _RenewalSummary(details: details, dateFormat: dateFormat),
        const SizedBox(height: AppSpacing.space32),
        const _Divider(),

        // Self-service actions.
        // Update payment method opens the *native* PaymentSheet in setup
        // mode — no browser, no portal. Apple Pay / Google Pay / cards
        // attach in the same chrome the user paid in.
        _ActionTile(
          icon: AdaptiveIcons.creditCard,
          label: l10n.subscriptionUpdatePaymentMethod,
          onTap: () => UpdatePaymentMethodFlow.run(context),
        ),
        const _Divider(),
        _ActionTile(
          icon: AdaptiveIcons.invoice,
          label: l10n.subscriptionViewInvoices,
          onTap: () => const SubscriptionInvoicesRoute().go(context),
        ),
        const _Divider(),
        if (details.cancelAtPeriodEnd)
          _ActionTile(
            icon: AdaptiveIcons.refresh,
            label: l10n.subscriptionReactivateAction,
            tone: _ActionTone.primary,
            onTap: state.isReactivating
                ? null
                : () => ReactivateSubscriptionSheet.show(context),
          )
        else
          _ActionTile(
            icon: AdaptiveIcons.cancel,
            label: l10n.subscriptionCancelAction,
            tone: _ActionTone.destructive,
            onTap: state.isCancelling
                ? null
                : () => CancelSubscriptionSheet.show(
                    context,
                    expiresAt: details.effectiveRenewalDate,
                  ),
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.details});
  final SubscriptionDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).languageCode,
    );
    final renewal = details.effectiveRenewalDate;

    final String label;
    final Color color;
    if (details.isCancelScheduled && renewal != null) {
      label = l10n.subscriptionStatusCancelsOn(dateFormat.format(renewal));
      color = AppColors.warning;
    } else {
      label = l10n.subscriptionStatusPremiumActive;
      color = AppColors.primary;
    }

    return Text(
      label,
      style: TextStyle(
        fontFamily: FontFamily.b612,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.method});
  final PaymentMethodPreview method;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.surfaceDark
            : AppColors.surfaceVariant,
        borderRadius: AppRadius.large20,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.medium8,
            ),
            child: Text(
              method.brandDisplay.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.last4 != null
                      ? '${method.brandDisplay}  ${l10n.subscriptionCardLast4(method.last4!)}'
                      : method.brandDisplay,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (method.formattedExpiry != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.subscriptionCardExpires(method.formattedExpiry!),
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 13,
                      color: AppColors.textSecondaryOf(theme.brightness),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewalSummary extends StatelessWidget {
  const _RenewalSummary({required this.details, required this.dateFormat});
  final SubscriptionDetails details;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final renewal = details.effectiveRenewalDate;
    if (renewal == null) return const SizedBox.shrink();

    final dateLine = details.cancelAtPeriodEnd
        ? l10n.subscriptionExpiresOn(dateFormat.format(renewal))
        : l10n.subscriptionRenewsOn(dateFormat.format(renewal));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLine,
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          l10n.premiumPriceLabel(PremiumPricing.displayPrice),
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 14,
            color: AppColors.textSecondaryOf(theme.brightness),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Free body
// ---------------------------------------------------------------------------

class _FreeBody extends StatefulWidget {
  const _FreeBody();

  @override
  State<_FreeBody> createState() => _FreeBodyState();
}

/// FREE-state of the manage-subscription page.
///
/// Used to show "Plan gratuit" + a paragraph + a button that opened
/// *another* sheet with the same info and another button — three
/// stacked surfaces for what's a single intent. Now the page itself is
/// the showcase: swipeable feature cards, price, single CTA → Stripe
/// PaymentSheet directly. One layer.
class _FreeBodyState extends State<_FreeBody> {
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
    setState(() => _isLoading = true);
    await PremiumCheckout.run(context);
    if (!mounted) return;
    setState(() => _isLoading = false);
    // Nothing else to do on success — the bloc state flip will rebuild
    // the parent into _PremiumBody automatically (via
    // SubscriptionBloc.LoadSubscription dispatched inside PremiumCheckout).
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final features = <_FreeFeature>[
      _FreeFeature(
        icon: Icons.auto_awesome_outlined,
        title: l10n.premiumFeaturePageAiTitle,
        body: l10n.premiumFeaturePageAiBody,
      ),
      _FreeFeature(
        icon: Icons.group_outlined,
        title: l10n.premiumFeaturePageViewersTitle,
        body: l10n.premiumFeaturePageViewersBody,
      ),
      _FreeFeature(
        icon: Icons.notifications_none_rounded,
        title: l10n.premiumFeaturePageOfflineTitle,
        body: l10n.premiumFeaturePageOfflineBody,
      ),
      _FreeFeature(
        icon: Icons.bookmark_border_rounded,
        title: l10n.premiumFeaturePagePostTripTitle,
        body: l10n.premiumFeaturePagePostTripBody,
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space24,
            AppSpacing.space24,
            AppSpacing.space24,
            0,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.subscriptionStatusFree,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryOf(theme.brightness),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: features.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _pageIndex = i);
            },
            itemBuilder: (context, index) =>
                _FreeFeaturePage(feature: features[index]),
          ),
        ),
        const SizedBox(height: AppSpacing.space16),
        _FreePageDots(count: features.length, currentIndex: _pageIndex),
        const SizedBox(height: AppSpacing.space24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CupertinoButton.filled(
                onPressed: _isLoading ? null : _handleUpgrade,
                child: _isLoading
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : Text(l10n.premiumCtaTry),
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
              SizedBox(height: mediaQuery.padding.bottom + AppSpacing.space24),
            ],
          ),
        ),
      ],
    );
  }
}

class _FreeFeature {
  final IconData icon;
  final String title;
  final String body;
  const _FreeFeature({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _FreeFeaturePage extends StatelessWidget {
  const _FreeFeaturePage({required this.feature});
  final _FreeFeature feature;

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

class _FreePageDots extends StatelessWidget {
  const _FreePageDots({required this.count, required this.currentIndex});
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

// ---------------------------------------------------------------------------
// Reusable list-tile-style actions
// ---------------------------------------------------------------------------

enum _ActionTone { neutral, primary, destructive }

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = _ActionTone.neutral,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final _ActionTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (tone) {
      _ActionTone.neutral => theme.colorScheme.onSurface,
      _ActionTone.primary => AppColors.primary,
      _ActionTone.destructive => AppColors.error,
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space16,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.space16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ),
            if (tone != _ActionTone.destructive)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textDisabled,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      child: Container(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.4),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading + error scaffolds
// ---------------------------------------------------------------------------

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CupertinoActivityIndicator());
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 16,
                color: AppColors.textSecondaryOf(Theme.of(context).brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            CupertinoButton(
              onPressed: onRetry,
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

// Static icon glyph wrapper so the action tiles use the same iconography on
// both platforms without each call site re-deciding.
class AdaptiveIcons {
  AdaptiveIcons._();
  static const IconData creditCard = Icons.credit_card_outlined;
  static const IconData invoice = Icons.receipt_long_outlined;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData cancel = Icons.cancel_outlined;
}
