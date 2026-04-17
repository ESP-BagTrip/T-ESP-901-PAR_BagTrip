import 'package:bagtrip/budget/widgets/budget_item_form.dart';
import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/budget_alert_banner.dart';
import 'package:bagtrip/design/widgets/review/budget_stripe.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/design/widgets/review/sheets/quick_preview_sheet.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/plan_trip/helpers/budget_breakdown.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Budget tab — summary at the top (`BudgetStripe`), recent expenses
/// inline, and quick-add via FAB. The "see full breakdown" nav is kept
/// as an opt-in footer; it no longer fires on a tap to a stripe/CTA row.
class BudgetPanel extends StatelessWidget {
  const BudgetPanel({
    super.key,
    required this.tripId,
    required this.budgetSummary,
    required this.budgetItems,
    required this.totalDays,
    required this.canEdit,
    required this.isCompleted,
    required this.role,
  });

  final String tripId;
  final BudgetSummary? budgetSummary;
  final List<BudgetItem> budgetItems;
  final int totalDays;
  final bool canEdit;
  final bool isCompleted;
  final String role;

  static const int _recentCount = 5;

  void _openFullPage(BuildContext context) {
    BudgetRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
    ).push(context);
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final bloc = context.read<TripDetailBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetItemForm(
        tripId: tripId,
        onSave: (data) {
          AppHaptics.medium();
          bloc.add(CreateBudgetItemFromDetail(data: data));
        },
      ),
    );
  }

  Future<void> _showEditSheet(BuildContext context, BudgetItem item) async {
    final bloc = context.read<TripDetailBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetItemForm(
        tripId: tripId,
        item: item,
        onSave: (data) {
          AppHaptics.medium();
          bloc.add(UpdateBudgetItemFromDetail(itemId: item.id, data: data));
        },
      ),
    );
  }

  void _deleteItem(BuildContext context, BudgetItem item) {
    AppHaptics.medium();
    context.read<TripDetailBloc>().add(
      DeleteBudgetItemFromDetail(itemId: item.id),
    );
  }

  Future<void> _showPreview(BuildContext context, BudgetItem item) async {
    final l10n = AppLocalizations.of(context)!;
    AppHaptics.light();
    await showQuickPreviewSheet(
      context: context,
      icon: item.category.icon,
      title: item.label,
      subtitle: item.category.label(l10n),
      body: _BudgetPreviewBody(item: item),
      primaryAction: QuickPreviewAction(
        label: l10n.panelActionEdit,
        icon: Icons.edit_rounded,
        onPressed: () {
          Navigator.of(context).pop();
          _showEditSheet(context, item);
        },
      ),
      destructiveAction: canEdit
          ? QuickPreviewAction(
              label: l10n.panelActionDelete,
              icon: Icons.delete_outline_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem(context, item);
              },
              isDestructive: true,
            )
          : null,
      openFullLabel: l10n.panelOpenFullBudget,
      onOpenFull: () => _openFullPage(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = budgetSummary;
    final hasNothing =
        (summary == null ||
            (summary.totalBudget <= 0 && summary.byCategory.isEmpty)) &&
        budgetItems.isEmpty;

    if (hasNothing) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ElegantEmptyState(
          icon: Icons.account_balance_wallet_rounded,
          title: l10n.emptyBudgetTitle,
          subtitle: canEdit ? l10n.emptyBudgetSubtitle : null,
          ctaLabel: canEdit ? l10n.panelQuickAddExpense : null,
          onCta: canEdit ? () => _showAddSheet(context) : null,
        ),
      );
    }

    final hasAlert = summary?.alertLevel != null;
    final entries = summary == null
        ? const <BudgetStripeEntry>[]
        : _breakdownEntries(summary, l10n);
    final sortedItems = [...budgetItems]
      ..sort((a, b) {
        final aDate = a.date ?? a.createdAt ?? DateTime(1970);
        final bDate = b.date ?? b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    final recent = sortedItems.take(_recentCount).toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space56 + AppSpacing.space40,
          ),
          children: [
            if (hasAlert && summary != null) ...[
              BudgetAlertBanner(summary: summary),
              const SizedBox(height: AppSpacing.space12),
            ],
            if (summary != null && summary.totalBudget > 0)
              BudgetStripe(
                total: summary.totalBudget,
                entries: entries,
                subtitle: _subtitle(l10n),
              ),
            if (recent.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space24),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                child: Text(
                  l10n.budgetRecentExpenses.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: ColorName.hint,
                  ),
                ),
              ),
              _RecentList(
                items: recent,
                canEdit: canEdit,
                onItemTap: (item) => _showPreview(context, item),
                onItemDelete: (item) => _deleteItem(context, item),
              ),
            ],
            const SizedBox(height: AppSpacing.space16),
            Center(
              child: TextButton(
                onPressed: () => _openFullPage(context),
                child: Text(
                  l10n.panelOpenFullBudget,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColorName.hint,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (canEdit)
          Positioned(
            bottom: AppSpacing.space24,
            right: AppSpacing.space24,
            child: PanelFab(
              label: l10n.panelQuickAddExpense,
              onTap: () => _showAddSheet(context),
            ),
          ),
      ],
    );
  }

  String _subtitle(AppLocalizations l10n) {
    if (totalDays <= 0) return l10n.reviewBudgetEstimationPrefix;
    return '${l10n.reviewBudgetEstimationPrefix} · ${l10n.summaryDaysCount(totalDays)}';
  }

  List<BudgetStripeEntry> _breakdownEntries(
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
}

class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.items,
    required this.canEdit,
    required this.onItemTap,
    required this.onItemDelete,
  });

  final List<BudgetItem> items;
  final bool canEdit;
  final void Function(BudgetItem) onItemTap;
  final void Function(BudgetItem) onItemDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.large24,
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.large24,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: ColorName.primarySoftLight),
              _ExpenseRow(
                item: items[i],
                canEdit: canEdit,
                onTap: () => onItemTap(items[i]),
                onDelete: () => onItemDelete(items[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.item,
    required this.canEdit,
    required this.onTap,
    required this.onDelete,
  });

  final BudgetItem item;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ColorName.primary.withValues(alpha: 0.12),
                borderRadius: AppRadius.medium8,
              ),
              child: Icon(
                item.category.icon,
                color: ColorName.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 15,
                      color: ColorName.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateLabel(item.date ?? item.createdAt),
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 11,
                      color: ColorName.hint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Text(
              item.amount.formatPrice(),
              style: TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 15,
                color: item.isPlanned ? ColorName.hint : ColorName.primaryDark,
                fontStyle: item.isPlanned ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );

    if (!canEdit) return row;

    return Dismissible(
      key: ValueKey('budget-panel-${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        AppHaptics.medium();
        return true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        color: ColorName.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: AdaptiveContextMenu(
        actions: [
          AdaptiveContextAction(
            label: l10n.panelActionEdit,
            icon: Icons.edit_outlined,
            onPressed: onTap,
          ),
          AdaptiveContextAction(
            label: l10n.panelActionDelete,
            icon: Icons.delete_outline_rounded,
            onPressed: onDelete,
            isDestructive: true,
          ),
        ],
        child: row,
      ),
    );
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM').format(date);
  }
}

class _BudgetPreviewBody extends StatelessWidget {
  const _BudgetPreviewBody({required this.item});

  final BudgetItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = item.date ?? item.createdAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.amount.formatPrice(),
          style: const TextStyle(
            fontFamily: FontFamily.dMSerifDisplay,
            fontSize: 36,
            color: ColorName.primaryDark,
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          item.isPlanned
              ? l10n.budgetForecasted.toUpperCase()
              : l10n.budgetConfirmed.toUpperCase(),
          style: const TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorName.hint,
            letterSpacing: 1.2,
          ),
        ),
        if (date != null) ...[
          const SizedBox(height: AppSpacing.space16),
          Text(
            DateFormat.yMMMMd().format(date),
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 14,
              color: ColorName.primaryDark,
            ),
          ),
        ],
      ],
    );
  }
}
