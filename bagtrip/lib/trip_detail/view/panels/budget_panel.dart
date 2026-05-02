import 'package:bagtrip/budget/widgets/budget_item_form.dart';
import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/budget_alert_banner.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/design/widgets/review/sheets/quick_preview_sheet.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = budgetSummary;

    // Topic 06 (B9) — viewer rendering. Server has already redacted every
    // monetary field (`totalSpent=0`, `confirmedTotal=0`, etc.) and shipped
    // a coarse-grained `budgetStatus` bucket. The panel renders the bucket
    // + the target only, never the items list.
    if (role == 'VIEWER') {
      return _ViewerBudgetPanel(summary: summary, l10n: l10n);
    }

    final hasSummaryTotals =
        summary != null &&
        (summary.confirmedTotal > 0 || summary.forecastedTotal > 0);
    final hasAlert = summary?.alertLevel != null;
    final forecasted = _sortDesc(
      budgetItems.where((i) => i.isPlanned).toList(),
    );
    final confirmed = _sortDesc(
      budgetItems.where((i) => !i.isPlanned).toList(),
    );
    // Both sections are always rendered — even on brand-new trips with no
    // items yet — so the user understands the forecast / real split and
    // sees where future expenses will land.

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
            if (hasSummaryTotals) ...[
              _DualTotalCard(summary: summary, l10n: l10n),
              const SizedBox(height: AppSpacing.space24),
            ],
            _BudgetSection(
              title: l10n.budgetForecastHeader,
              subtitle: l10n.budgetForecastSubtitle,
              items: forecasted,
              canEdit: canEdit,
              emptyMessage: l10n.budgetForecastEmpty,
              onItemTap: (item) => _showPreview(context, item),
              onItemDelete: (item) => _deleteItem(context, item),
            ),
            const SizedBox(height: AppSpacing.space24),
            _BudgetSection(
              title: l10n.budgetRealHeader,
              subtitle: l10n.budgetRealSubtitle,
              items: confirmed,
              canEdit: canEdit,
              emptyMessage: l10n.budgetRealEmpty,
              onItemTap: (item) => _showPreview(context, item),
              onItemDelete: (item) => _deleteItem(context, item),
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

  List<BudgetItem> _sortDesc(List<BudgetItem> list) {
    list.sort((a, b) {
      final aDate = a.date ?? a.createdAt ?? DateTime(1970);
      final bDate = b.date ?? b.createdAt ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return list;
  }
}

/// A single budget section (Forecasted / Real). Shows a serif section title,
/// a quiet subtitle, and a rounded list of items — or a light empty hint
/// when the section is empty. Both sections are always rendered so the user
/// can see the two totals at a glance.
class _BudgetSection extends StatelessWidget {
  const _BudgetSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.canEdit,
    required this.emptyMessage,
    required this.onItemTap,
    required this.onItemDelete,
  });

  final String title;
  final String subtitle;
  final List<BudgetItem> items;
  final bool canEdit;
  final String emptyMessage;
  final void Function(BudgetItem) onItemTap;
  final void Function(BudgetItem) onItemDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 12,
            color: AppColors.reviewInk.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: AppSpacing.space12),
        if (items.isEmpty)
          _EmptySectionPlaceholder(message: emptyMessage)
        else
          _RecentList(
            items: items,
            canEdit: canEdit,
            onItemTap: onItemTap,
            onItemDelete: onItemDelete,
          ),
      ],
    );
  }
}

class _EmptySectionPlaceholder extends StatelessWidget {
  const _EmptySectionPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF7),
        borderRadius: AppRadius.large24,
        border: Border.all(
          color: const Color(0xFF0D1F35).withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space16,
        ),
        child: Text(
          message,
          style: TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: AppColors.reviewInk.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

/// Luxury card surfacing the two totals the user asked for: **real** (already
/// validated expenses) vs **forecasted** (proposed, pending validation).
/// The backend already splits them via `BudgetSummary.confirmedTotal` and
/// `forecastedTotal`; this widget just renders them side-by-side with a
/// hairline divider and a whisper delta.
class _DualTotalCard extends StatelessWidget {
  const _DualTotalCard({required this.summary, required this.l10n});

  final BudgetSummary summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final delta = summary.confirmedTotal - summary.forecastedTotal;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF7),
        borderRadius: AppRadius.large24,
        border: Border.all(
          color: const Color(0xFF0D1F35).withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _DualTotalColumn(
                      label: l10n.budgetRealHeader,
                      amount: summary.confirmedTotal,
                      accent: AppColors.reviewInk,
                    ),
                  ),
                  const VerticalDivider(
                    width: AppSpacing.space24,
                    thickness: 0.5,
                    color: AppColors.reviewDividerFaint,
                  ),
                  Expanded(
                    child: _DualTotalColumn(
                      label: l10n.budgetForecastHeader,
                      amount: summary.forecastedTotal,
                      accent: AppColors.reviewMuted,
                      italic: true,
                    ),
                  ),
                ],
              ),
            ),
            if (delta != 0) ...[
              const SizedBox(height: AppSpacing.space16),
              Text(
                delta > 0
                    ? l10n.budgetDeltaOver(delta.formatPrice())
                    : l10n.budgetDeltaUnder((-delta).formatPrice()),
                style: TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 12,
                  letterSpacing: 0.2,
                  color: AppColors.reviewInk.withValues(alpha: 0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DualTotalColumn extends StatelessWidget {
  const _DualTotalColumn({
    required this.label,
    required this.amount,
    required this.accent,
    this.italic = false,
  });

  final String label;
  final double amount;
  final Color accent;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.8,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          amount.formatPrice(),
          style: TextStyle(
            fontFamily: FontFamily.dMSerifDisplay,
            fontSize: 32,
            height: 1,
            fontWeight: FontWeight.w400,
            letterSpacing: -1,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            color: accent,
          ),
        ),
      ],
    );
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

/// VIEWER-only rendering (topic 06, B9). Shows the trip's budget target
/// and the coarse-grained `budgetStatus` bucket emitted by the server.
/// Renders no spent / remaining / per-category figure : the server has
/// already redacted them, so even a tampered build can't display what
/// it doesn't have.
class _ViewerBudgetPanel extends StatelessWidget {
  const _ViewerBudgetPanel({required this.summary, required this.l10n});

  final BudgetSummary? summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final status = summary?.budgetStatus;
    final target = summary?.totalBudget ?? 0;
    final (statusLabel, statusColor) = _statusPresentation(status);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFBFAF7),
            borderRadius: AppRadius.large24,
            border: Border.all(
              color: const Color(0xFF0D1F35).withValues(alpha: 0.06),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetTotal,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: ColorName.hint,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  target > 0 ? target.formatPrice() : '—',
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 28,
                    color: AppColors.reviewInk,
                  ),
                ),
                if (statusLabel != null) ...[
                  const SizedBox(height: AppSpacing.space16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space12,
                      vertical: AppSpacing.space8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: FontFamily.dMSans,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space16),
                Text(
                  l10n.budgetViewerNoFiguresHint,
                  style: TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.reviewInk.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  (String?, Color) _statusPresentation(String? status) {
    return switch (status) {
      'onTrack' => (l10n.budgetViewerStatusOnTrack, ColorName.secondary),
      'tight' => (l10n.budgetViewerStatusTight, ColorName.warning),
      'overBudget' => (l10n.budgetViewerStatusOverBudget, AppColors.dangerIcon),
      _ => (null, ColorName.hint),
    };
  }
}
