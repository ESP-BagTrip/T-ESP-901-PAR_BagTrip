import 'package:bagtrip/budget/bloc/budget_bloc.dart';
import 'package:bagtrip/budget/widgets/budget_alert_banner.dart';
import 'package:bagtrip/budget/widgets/budget_estimate_sheet.dart';
import 'package:bagtrip/budget/widgets/budget_item_card.dart';
import 'package:bagtrip/budget/widgets/budget_item_form.dart';
import 'package:bagtrip/budget/widgets/budget_summary_header.dart';
import 'package:bagtrip/components/empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BudgetView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final canEdit = role != 'VIEWER' && !isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.budgetItems),
        actions: [
          if (canEdit && AdaptivePlatform.isIOS)
            IconButton(
              icon: const Icon(CupertinoIcons.add),
              onPressed: () => _showForm(context, tripId),
            ),
        ],
      ),
      body: BlocConsumer<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (state is BudgetEstimated) {
            _showEstimateSheet(context);
          }
          if (state is BudgetQuotaExceeded) {
            PremiumPaywall.show(context);
          }
        },
        builder: (context, state) {
          if (state is BudgetLoading) {
            return const LoadingView();
          }
          if (state is BudgetEstimating) {
            return const LoadingView();
          }
          if (state is BudgetError) {
            return ErrorView(
              message: toUserFriendlyMessage(
                state.error,
                AppLocalizations.of(context)!,
              ),
              onRetry: () =>
                  context.read<BudgetBloc>().add(LoadBudget(tripId: tripId)),
            );
          }
          if (state is BudgetLoaded || state is BudgetEstimated) {
            final items = state is BudgetLoaded
                ? state.items
                : (state as BudgetEstimated).items;
            final summary = state is BudgetLoaded
                ? state.summary
                : (state as BudgetEstimated).summary;
            return _buildContent(context, items, summary, canEdit);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: canEdit && !AdaptivePlatform.isIOS
          ? FloatingActionButton(
              onPressed: () => _showForm(context, tripId),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<BudgetItem> items,
    BudgetSummary summary,
    bool canEdit,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isViewer = role == 'VIEWER';
    final isReadOnly = isViewer || isCompleted;

    if (items.isEmpty && !isReadOnly) {
      return EmptyState(
        icon: Icons.wallet_outlined,
        title: l10n.noExpenses,
        subtitle: l10n.trackExpensesAndPlan,
      );
    }

    if (isViewer) {
      return ListView(
        padding: AppSpacing.allEdgeInsetSpace16,
        children: [BudgetSummaryHeader(summary: summary, isViewer: true)],
      );
    }

    // Separate confirmed and forecasted items
    final confirmedItems = items
        .where((item) => item.sourceType != null || !item.isPlanned)
        .toList();
    final forecastedItems = items
        .where((item) => item.sourceType == null && item.isPlanned)
        .toList();

    return ListView(
      padding: AppSpacing.allEdgeInsetSpace16,
      children: [
        if (summary.alertLevel != null) BudgetAlertBanner(summary: summary),
        BudgetSummaryHeader(summary: summary),

        // Estimate button
        if (canEdit)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space16),
            child: OutlinedButton.icon(
              onPressed: () => context.read<BudgetBloc>().add(
                EstimateBudget(tripId: tripId),
              ),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(l10n.budgetEstimateButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.medium8,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space16,
                ),
              ),
            ),
          ),

        if (summary.byCategory.isNotEmpty) ...[
          Text(
            l10n.expenseCategory,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.space8),
          Wrap(
            spacing: AppSpacing.space8,
            runSpacing: AppSpacing.space4,
            children: summary.byCategory.entries.map((entry) {
              return Chip(
                label: Text(
                  '${entry.key}: ${entry.value.toStringAsFixed(2)} \u20ac',
                ),
                backgroundColor: _categoryColor(entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.space16),
        ],

        // Confirmed section
        if (confirmedItems.isNotEmpty) ...[
          _buildSectionHeader(context, l10n.budgetConfirmed),
          ...confirmedItems.map(
            (item) => BudgetItemCard(
              item: item,
              onEdit: isReadOnly
                  ? null
                  : () => _showForm(context, tripId, item: item),
              onDelete: isReadOnly
                  ? null
                  : () => context.read<BudgetBloc>().add(
                      DeleteBudgetItem(tripId: tripId, itemId: item.id),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
        ],

        // Forecasted section
        if (forecastedItems.isNotEmpty) ...[
          _buildSectionHeader(context, l10n.budgetForecasted),
          ...forecastedItems.map(
            (item) => BudgetItemCard(
              item: item,
              onEdit: isReadOnly
                  ? null
                  : () => _showForm(context, tripId, item: item),
              onDelete: isReadOnly
                  ? null
                  : () => context.read<BudgetBloc>().add(
                      DeleteBudgetItem(tripId: tripId, itemId: item.id),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.onSurface,
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'FLIGHT':
        return Colors.blue.shade100;
      case 'ACCOMMODATION':
        return Colors.purple.shade100;
      case 'FOOD':
        return Colors.orange.shade100;
      case 'ACTIVITY':
        return Colors.teal.shade100;
      case 'TRANSPORT':
        return Colors.indigo.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  void _showForm(BuildContext context, String tripId, {BudgetItem? item}) {
    final bloc = context.read<BudgetBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BudgetItemForm(
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
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEstimateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetBloc>(),
        child: BudgetEstimateSheet(tripId: tripId),
      ),
    );
  }
}
