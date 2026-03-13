import 'package:bagtrip/budget/bloc/budget_bloc.dart';
import 'package:bagtrip/budget/widgets/budget_item_card.dart';
import 'package:bagtrip/budget/widgets/budget_item_form.dart';
import 'package:bagtrip/budget/widgets/budget_summary_header.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BudgetView extends StatelessWidget {
  final String tripId;

  const BudgetView({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, state) {
          if (state is BudgetLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BudgetError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed:
                        () => context.read<BudgetBloc>().add(
                          LoadBudget(tripId: tripId),
                        ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is BudgetLoaded) {
            if (state.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wallet_outlined,
                      size: 64,
                      color: AppColors.hint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No budget items yet',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: AppColors.hint),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add expenses to track your trip budget',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                BudgetSummaryHeader(summary: state.summary),
                if (state.summary.byCategory.isNotEmpty) ...[
                  Text(
                    'By Category',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        state.summary.byCategory.entries.map((entry) {
                          return Chip(
                            label: Text(
                              '${entry.key}: ${entry.value.toStringAsFixed(2)} \u20ac',
                            ),
                            backgroundColor: _categoryColor(entry.key),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                ...state.items.map(
                  (item) => BudgetItemCard(
                    item: item,
                    onEdit: () => _showForm(context, tripId, item: item),
                    onDelete:
                        () => context.read<BudgetBloc>().add(
                          DeleteBudgetItem(tripId: tripId, itemId: item.id),
                        ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, tripId),
        child: const Icon(Icons.add),
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
      builder:
          (_) => BudgetItemForm(
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
}
