import 'package:bagtrip/components/adaptive/adaptive_app_bar.dart';
import 'package:bagtrip/components/adaptive/adaptive_action_sheet.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/invoice.dart';
import 'package:bagtrip/subscription/bloc/subscription_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pure-list invoices view.
///
/// No card chrome, no badges, no zebra stripes. Each row is just a number,
/// amount and date. Tap → opens Stripe-hosted invoice. Long-press → action
/// sheet with PDF download. Empty state uses [ElegantEmptyState] with the
/// app's standard motion.
class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SubscriptionBloc>().add(LoadInvoices());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AdaptiveAppBar.build(
        context: context,
        title: l10n.invoicesPageTitle,
      ),
      body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) {
          if (state.invoicesLoading && state.invoices.isEmpty) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (state.invoicesError != null && state.invoices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space24),
                child: Text(
                  toUserFriendlyMessage(state.invoicesError!, l10n),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    color: AppColors.textSecondaryOf(
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
              ),
            );
          }
          if (state.invoices.isEmpty) {
            return ElegantEmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.invoicesEmpty,
              subtitle: l10n.invoicesEmptySubtitle,
            );
          }
          return RefreshIndicator.adaptive(
            onRefresh: () async {
              context.read<SubscriptionBloc>().add(LoadInvoices());
              await context.read<SubscriptionBloc>().stream.firstWhere(
                (s) => !s.invoicesLoading,
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16),
              itemCount: state.invoices.length,
              separatorBuilder: (_, _) => Container(
                height: 1,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space24,
                ),
                color: AppColors.border.withValues(alpha: 0.4),
              ),
              itemBuilder: (context, index) {
                final invoice = state.invoices[index];
                return _InvoiceRow(invoice: invoice);
              },
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    );
    final amount = invoice.amountPaidMajor;
    final amountText = amount != null
        ? NumberFormat.currency(
            locale: Localizations.localeOf(context).toString(),
            symbol: _currencySymbol(invoice.currency),
            decimalDigits: 2,
          ).format(amount)
        : '—';

    return InkWell(
      onTap: invoice.hostedInvoiceUrl == null
          ? null
          : () => _open(invoice.hostedInvoiceUrl!),
      onLongPress: () => _openContextActions(context, invoice),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space24,
          vertical: AppSpacing.space16,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.number ?? invoice.id,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 13,
                      color: AppColors.textSecondaryOf(theme.brightness),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.created != null
                        ? dateFormat.format(invoice.created!)
                        : '—',
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (invoice.status != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _statusLabel(invoice.status!, l10n),
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              amountText,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    HapticFeedback.lightImpact();
    // In-app browser (SFSafariViewController on iOS, Custom Tabs on Android)
    // — the invoice slides up in the same chrome the user lives in, no
    // jarring jump to Safari.
    await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
  }

  Future<void> _openContextActions(
    BuildContext context,
    Invoice invoice,
  ) async {
    HapticFeedback.selectionClick();
    final l10n = AppLocalizations.of(context)!;
    await showAdaptiveActionSheet(
      context: context,
      actions: [
        if (invoice.hostedInvoiceUrl != null)
          AdaptiveAction(
            label: l10n.invoicesViewOnStripe,
            onPressed: () => _open(invoice.hostedInvoiceUrl!),
          ),
        if (invoice.invoicePdf != null)
          AdaptiveAction(
            label: l10n.invoicesDownloadPdf,
            onPressed: () => _open(invoice.invoicePdf!),
          ),
      ],
    );
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    return switch (status) {
      'paid' => l10n.invoiceStatusPaid,
      'open' => l10n.invoiceStatusOpen,
      'void' => l10n.invoiceStatusVoid,
      'draft' => l10n.invoiceStatusDraft,
      'uncollectible' => l10n.invoiceStatusUncollectible,
      _ => status,
    };
  }

  String _currencySymbol(String? currency) {
    return switch (currency?.toLowerCase()) {
      'eur' => '€',
      'usd' => r'$',
      'gbp' => '£',
      _ => currency?.toUpperCase() ?? '',
    };
  }
}
