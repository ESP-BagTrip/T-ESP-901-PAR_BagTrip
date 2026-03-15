import 'package:bagtrip/budget/bloc/budget_bloc.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_estimation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class BudgetEstimateSheet extends StatefulWidget {
  final String tripId;

  const BudgetEstimateSheet({super.key, required this.tripId});

  @override
  State<BudgetEstimateSheet> createState() => _BudgetEstimateSheetState();
}

class _BudgetEstimateSheetState extends State<BudgetEstimateSheet> {
  final _budgetController = TextEditingController();

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.cornerRadius20),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.pill,
                  ),
                ),
              ),
              Padding(
                padding: AppSpacing.allEdgeInsetSpace16,
                child: Text(
                  l10n.budgetEstimateTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<BudgetBloc, BudgetState>(
                  builder: (context, state) {
                    if (state is BudgetEstimating) {
                      return _buildShimmer(scrollController);
                    }
                    if (state is BudgetEstimated) {
                      return _buildEstimation(
                        context,
                        scrollController,
                        state.estimation,
                        l10n,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmer(ScrollController controller) {
    return ListView.builder(
      controller: controller,
      padding: AppSpacing.horizontalSpace16,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space8),
          child: Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Container(
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.medium8,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstimation(
    BuildContext context,
    ScrollController controller,
    BudgetEstimation estimation,
    AppLocalizations l10n,
  ) {
    final breakdownItems = <_BreakdownEntry>[
      if (estimation.accommodationPerNight != null)
        _BreakdownEntry(
          icon: Icons.hotel,
          label: l10n.budgetAccommodationPerNight,
          amount: estimation.accommodationPerNight!,
        ),
      if (estimation.mealsPerDayPerPerson != null)
        _BreakdownEntry(
          icon: Icons.restaurant,
          label: l10n.budgetMealsPerDay,
          amount: estimation.mealsPerDayPerPerson!,
        ),
      if (estimation.localTransportPerDay != null)
        _BreakdownEntry(
          icon: Icons.directions_car,
          label: l10n.budgetLocalTransport,
          amount: estimation.localTransportPerDay!,
        ),
      if (estimation.activitiesTotal != null)
        _BreakdownEntry(
          icon: Icons.sports_tennis,
          label: l10n.budgetActivitiesTotal,
          amount: estimation.activitiesTotal!,
        ),
    ];

    final totalMin = estimation.totalMin ?? 0;
    final totalMax = estimation.totalMax ?? 0;
    final average = (totalMin + totalMax) / 2;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: controller,
            padding: AppSpacing.horizontalSpace16,
            children: [
              ...breakdownItems.map(
                (entry) => _buildBreakdownRow(
                  context,
                  entry.icon,
                  entry.label,
                  entry.amount,
                  estimation.currency,
                ),
              ),
              if (estimation.breakdownNotes != null &&
                  estimation.breakdownNotes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space16),
                  child: Text(
                    estimation.breakdownNotes!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.hint),
                  ),
                ),
            ],
          ),
        ),
        // Bottom section with range and actions
        Container(
          padding: AppSpacing.allEdgeInsetSpace16,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              Text(
                l10n.budgetTotalRange(
                  totalMin.toStringAsFixed(0),
                  totalMax.toStringAsFixed(0),
                  estimation.currency,
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showModifyDialog(
                        context,
                        average,
                        estimation.currency,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium8,
                        ),
                      ),
                      child: Text(l10n.budgetEstimateModify),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        context.read<BudgetBloc>().add(
                          AcceptBudgetEstimate(
                            tripId: widget.tripId,
                            budgetTotal: average,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium8,
                        ),
                      ),
                      child: Text(l10n.budgetEstimateAccept),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context,
    IconData icon,
    String label,
    double amount,
    String currency,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: Container(
        padding: AppSpacing.allEdgeInsetSpace16,
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.medium8,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: AppSpacing.space16),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              '${amount.toStringAsFixed(2)} $currency',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showModifyDialog(
    BuildContext context,
    double defaultValue,
    String currency,
  ) {
    final l10n = AppLocalizations.of(context)!;
    _budgetController.text = defaultValue.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.budgetEstimateModify),
        content: TextField(
          controller: _budgetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: currency),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(_budgetController.text);
              if (value != null && value > 0) {
                context.read<BudgetBloc>().add(
                  AcceptBudgetEstimate(
                    tripId: widget.tripId,
                    budgetTotal: value,
                  ),
                );
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              }
            },
            child: Text(l10n.budgetEstimateAccept),
          ),
        ],
      ),
    );
  }
}

class _BreakdownEntry {
  final IconData icon;
  final String label;
  final double amount;

  const _BreakdownEntry({
    required this.icon,
    required this.label,
    required this.amount,
  });
}
