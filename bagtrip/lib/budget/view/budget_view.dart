import 'package:bagtrip/budget/bloc/budget_bloc.dart';
import 'package:bagtrip/budget/widgets/budget_estimate_sheet.dart';
import 'package:bagtrip/budget/widgets/budget_item_form.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/design/widgets/review/budget_alert_banner.dart';
import 'package:bagtrip/design/widgets/review/budget_stripe.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/sub_page_hero.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/plan_trip/helpers/budget_breakdown.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BudgetView extends StatefulWidget {
  final String tripId;
  final String role;
  final bool isCompleted;

  const BudgetView({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  @override
  State<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> with TickerProviderStateMixin {
  late final PanelFooterCtaController _footerController;

  @override
  void initState() {
    super.initState();
    _footerController = PanelFooterCtaController(vsync: this);
    _footerController.show();
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  bool get _canEdit => widget.role != 'VIEWER' && !widget.isCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: ColorName.surfaceVariant,
      body: Column(
        children: [
          SubPageHero(
            title: l10n.budgetItems,
            trailing: _canEdit
                ? [
                    HeroNavButton(
                      icon: Icons.auto_awesome_rounded,
                      tooltip: l10n.budgetEstimateButton,
                      onPressed: () {
                        AppHaptics.light();
                        context.read<BudgetBloc>().add(
                          EstimateBudget(tripId: widget.tripId),
                        );
                      },
                    ),
                  ]
                : null,
          ),
          Expanded(
            child: BlocConsumer<BudgetBloc, BudgetState>(
              listener: (context, state) {
                if (state is BudgetEstimated) {
                  _showEstimateSheet(context);
                } else if (state is BudgetQuotaExceeded) {
                  PremiumPaywall.show(context);
                } else if (state is BudgetLoaded) {
                  context.read<TripDetailBloc>().add(RefreshTripDetail());
                }
              },
              builder: (context, state) {
                if (state is BudgetLoading || state is BudgetEstimating) {
                  return const LoadingView();
                }
                if (state is BudgetError) {
                  return ErrorView(
                    message: toUserFriendlyMessage(state.error, l10n),
                    onRetry: () => context.read<BudgetBloc>().add(
                      LoadBudget(tripId: widget.tripId),
                    ),
                  );
                }
                if (state is BudgetLoaded || state is BudgetEstimated) {
                  final items = state is BudgetLoaded
                      ? state.items
                      : (state as BudgetEstimated).items;
                  final summary = state is BudgetLoaded
                      ? state.summary
                      : (state as BudgetEstimated).summary;
                  return _buildContent(context, items, summary);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _canEdit
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space8,
                  AppSpacing.space16,
                  AppSpacing.space16,
                ),
                child: PanelFooterCta(
                  controller: _footerController,
                  child: PillCtaButton(
                    label: AppLocalizations.of(context)!.addExpense,
                    leadingIcon: Icons.add_rounded,
                    onTap: () => _showForm(context, widget.tripId),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<BudgetItem> items,
    BudgetSummary summary,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty && summary.totalBudget <= 0) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ElegantEmptyState(
          icon: Icons.wallet_outlined,
          title: l10n.emptyBudgetTitle,
          subtitle: _canEdit ? l10n.emptyBudgetSubtitle : null,
        ),
      );
    }

    final confirmedItems = items
        .where((i) => i.sourceType != null || !i.isPlanned)
        .toList();
    final forecastedItems = items
        .where((i) => i.sourceType == null && i.isPlanned)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space32 + 72,
      ),
      children: [
        if (summary.alertLevel != null) ...[
          BudgetAlertBanner(summary: summary),
          const SizedBox(height: AppSpacing.space12),
        ],
        BudgetStripe(
          total: summary.totalBudget,
          subtitle: l10n.reviewBudgetEstimationPrefix,
          entries: _entries(summary, l10n),
        ),
        const SizedBox(height: AppSpacing.space16),
        if (confirmedItems.isNotEmpty) ...[
          _SectionLabel(text: l10n.budgetConfirmed),
          const SizedBox(height: AppSpacing.space8),
          _ItemGroup(
            items: confirmedItems,
            canEdit: _canEdit,
            tripId: widget.tripId,
            onEdit: (item) => _showForm(context, widget.tripId, item: item),
          ),
          const SizedBox(height: AppSpacing.space16),
        ],
        if (forecastedItems.isNotEmpty) ...[
          _SectionLabel(text: l10n.budgetForecasted),
          const SizedBox(height: AppSpacing.space8),
          _ItemGroup(
            items: forecastedItems,
            canEdit: _canEdit,
            tripId: widget.tripId,
            onEdit: (item) => _showForm(context, widget.tripId, item: item),
          ),
        ],
      ],
    );
  }

  List<BudgetStripeEntry> _entries(
    BudgetSummary summary,
    AppLocalizations l10n,
  ) {
    final remapped = <String, dynamic>{};
    summary.byCategory.forEach((key, value) {
      final normalized = _normalize(key);
      if (normalized != null) remapped[normalized] = value;
    });
    return extractBudgetEntries(l10n, remapped);
  }

  String? _normalize(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('flight')) return 'flights';
    if (lower.contains('accommodation') || lower.contains('hotel')) {
      return 'accommodation';
    }
    if (lower.contains('food') || lower.contains('meal')) return 'meals';
    if (lower.contains('transport')) return 'transport';
    if (lower.contains('activit')) return 'activities';
    return null;
  }

  void _showForm(BuildContext context, String tripId, {BudgetItem? item}) {
    final bloc = context.read<BudgetBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _FormWrapper(
        child: BlocProvider.value(
          value: bloc,
          child: BudgetItemForm(
            tripId: tripId,
            item: item,
            onSave: (data) {
              if (item != null) {
                bloc.add(
                  UpdateBudgetItem(tripId: tripId, itemId: item.id, data: data),
                );
              } else {
                bloc.add(CreateBudgetItem(tripId: tripId, data: data));
              }
              Navigator.of(sheetCtx).pop();
            },
          ),
        ),
      ),
    );
  }

  void _showEstimateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetBloc>(),
        child: BudgetEstimateSheet(tripId: widget.tripId),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: FontFamily.dMSans,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: ColorName.hint,
      ),
    );
  }
}

class _ItemGroup extends StatelessWidget {
  const _ItemGroup({
    required this.items,
    required this.canEdit,
    required this.tripId,
    required this.onEdit,
  });

  final List<BudgetItem> items;
  final bool canEdit;
  final String tripId;
  final ValueChanged<BudgetItem> onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        primary: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: ColorName.primarySoftLight),
        itemBuilder: (context, idx) {
          final item = items[idx];
          return _BudgetItemRow(
            item: item,
            canEdit: canEdit,
            onEdit: () => onEdit(item),
            onDelete: () {
              AppHaptics.medium();
              context.read<BudgetBloc>().add(
                DeleteBudgetItem(tripId: tripId, itemId: item.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _BudgetItemRow extends StatelessWidget {
  const _BudgetItemRow({
    required this.item,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetItem item;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canEdit ? onEdit : null,
      borderRadius: AppRadius.large16,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ColorName.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    item.category.name.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                      color: ColorName.hint,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              item.amount.formatPrice(),
              style: const TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: ColorName.primaryDark,
              ),
            ),
            if (canEdit)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: ColorName.hint,
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

class _FormWrapper extends StatelessWidget {
  const _FormWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.cornerRadius24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.space12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorName.hint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
