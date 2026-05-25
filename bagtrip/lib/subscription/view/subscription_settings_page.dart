import 'package:bagtrip/components/adaptive/adaptive_indicator.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/payment_method_preview.dart';
import 'package:bagtrip/models/subscription_details.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/profile/widgets/profile_detail_labeled_row.dart';
import 'package:bagtrip/profile/widgets/profile_detail_menu_row.dart';
import 'package:bagtrip/profile/widgets/profile_detail_scaffold.dart';
import 'package:bagtrip/profile/widgets/profile_detail_style.dart';
import 'package:bagtrip/profile/widgets/profile_menu_group_card.dart';
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

/// Manage subscription — unified profile detail layout.
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

    return ProfileDetailScaffold(
      title: l10n.subscriptionPageTitle,
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listenWhen: (prev, curr) =>
            prev.actionInFlight != SubscriptionAction.idle &&
            curr.actionInFlight == SubscriptionAction.idle &&
            curr.error == null,
        listener: (context, state) {},
        builder: (context, state) {
          if (state.isLoading && !state.hasData) {
            return const Center(child: AdaptiveIndicator());
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
    final renewal = details.effectiveRenewalDate;

    final statusLabel = _statusLabel(context, details, dateFormat);
    final statusColor = _statusColor(details);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space24,
        AppSpacing.space16,
        AppSpacing.space48,
      ),
      children: [
        FormSectionHeader(
          label: l10n.subscriptionSectionStatus,
          icon: Icons.workspace_premium_outlined,
        ),
        ProfileMenuGroupCard(
          children: [
            ProfileDetailLabeledRow(
              icon: Icons.workspace_premium_outlined,
              iconColor: ProfileDetailStyle.iconAccentSecondary(),
              label: '',
              title: statusLabel,
              showLabel: false,
              titleColor: statusColor,
              cardSerifTypography: true,
            ),
          ],
        ),
        if (details.paymentMethod != null) ...[
          const SizedBox(height: AppSpacing.space24),
          FormSectionHeader(
            label: l10n.subscriptionSectionPayment,
            icon: Icons.credit_card_outlined,
          ),
          ProfileMenuGroupCard(
            children: [_PaymentMethodRow(method: details.paymentMethod!)],
          ),
        ],
        if (renewal != null) ...[
          const SizedBox(height: AppSpacing.space24),
          FormSectionHeader(
            label: l10n.subscriptionSectionBilling,
            icon: Icons.event_outlined,
          ),
          ProfileMenuGroupCard(
            children: [
              ProfileDetailLabeledRow(
                icon: Icons.calendar_today_outlined,
                iconColor: ProfileDetailStyle.iconAccentSecondary(),
                label: '',
                title: details.cancelAtPeriodEnd
                    ? l10n.subscriptionExpiresOn(dateFormat.format(renewal))
                    : l10n.subscriptionRenewsOn(dateFormat.format(renewal)),
                subtitle: l10n.premiumPriceLabel(PremiumPricing.displayPrice),
                showLabel: false,
                cardSerifTypography: true,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.space24),
        FormSectionHeader(
          label: l10n.subscriptionSectionManage,
          icon: Icons.settings_outlined,
        ),
        ProfileMenuGroupCard(children: _manageActions(context, state, details)),
      ],
    );
  }

  List<Widget> _manageActions(
    BuildContext context,
    SubscriptionState state,
    SubscriptionDetails details,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return [
      ProfileDetailMenuRow(
        icon: Icons.credit_card_outlined,
        iconColor: ProfileDetailStyle.iconAccentSecondary(),
        title: l10n.subscriptionUpdatePaymentMethod,
        cardSerifTypography: true,
        onTap: () => UpdatePaymentMethodFlow.run(context),
      ),
      ProfileDetailMenuRow(
        icon: Icons.receipt_long_outlined,
        iconColor: ProfileDetailStyle.iconAccentSecondary(),
        title: l10n.subscriptionViewInvoices,
        cardSerifTypography: true,
        onTap: () => const SubscriptionInvoicesRoute().go(context),
      ),
      if (details.cancelAtPeriodEnd)
        ProfileDetailMenuRow(
          icon: Icons.refresh_rounded,
          iconColor: ProfileDetailStyle.iconAccentPrimary(),
          title: l10n.subscriptionReactivateAction,
          titleColor: AppColors.primary,
          cardSerifTypography: true,
          onTap: state.isReactivating
              ? null
              : () => ReactivateSubscriptionSheet.show(context),
        )
      else
        ProfileDetailMenuRow(
          icon: Icons.cancel_outlined,
          iconColor: ProfileDetailStyle.iconAccentDestructive(),
          title: l10n.subscriptionCancelAction,
          titleColor: AppColors.error,
          showChevron: false,
          cardSerifTypography: true,
          onTap: state.isCancelling
              ? null
              : () => CancelSubscriptionSheet.show(
                  context,
                  expiresAt: details.effectiveRenewalDate,
                ),
        ),
    ];
  }

  String _statusLabel(
    BuildContext context,
    SubscriptionDetails details,
    DateFormat dateFormat,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final renewal = details.effectiveRenewalDate;
    if (details.isCancelScheduled && renewal != null) {
      return l10n.subscriptionStatusCancelsOn(dateFormat.format(renewal));
    }
    return l10n.subscriptionStatusPremiumActive;
  }

  Color _statusColor(SubscriptionDetails details) {
    if (details.isCancelScheduled) {
      return AppColors.warning;
    }
    return AppColors.primary;
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({required this.method});
  final PaymentMethodPreview method;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = method.last4 != null
        ? '${method.brandDisplay}  ${l10n.subscriptionCardLast4(method.last4!)}'
        : method.brandDisplay;

    return ProfileDetailLabeledRow(
      icon: Icons.credit_card_outlined,
      iconColor: ProfileDetailStyle.iconAccentSecondary(),
      label: '',
      title: title,
      subtitle: method.formattedExpiry != null
          ? l10n.subscriptionCardExpires(method.formattedExpiry!)
          : null,
      showLabel: false,
      cardSerifTypography: true,
    );
  }
}

class _FreeBody extends StatefulWidget {
  const _FreeBody();

  @override
  State<_FreeBody> createState() => _FreeBodyState();
}

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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
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
            AppSpacing.space16,
            AppSpacing.space24,
            AppSpacing.space16,
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
                color: ProfileDetailStyle.subtitleColor(
                  brightness,
                  enabled: true,
                ),
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
                  fontFamily: FontFamily.dMSerifDisplay,
                  fontSize: 14,
                  color: ProfileDetailStyle.subtitleColor(
                    brightness,
                    enabled: true,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                l10n.premiumDisclaimerCancelAnytime,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
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
  const _FreeFeature({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _FreeFeaturePage extends StatelessWidget {
  const _FreeFeaturePage({required this.feature});
  final _FreeFeature feature;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
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
              color: ProfileDetailStyle.titleColor(brightness, enabled: true),
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
              color: ProfileDetailStyle.subtitleColor(
                brightness,
                enabled: true,
              ),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
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
                color: ProfileDetailStyle.subtitleColor(
                  brightness,
                  enabled: true,
                ),
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
