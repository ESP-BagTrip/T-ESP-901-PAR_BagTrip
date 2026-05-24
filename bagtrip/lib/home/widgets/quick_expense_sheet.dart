import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/cubit/quick_expense_cubit.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QuickExpenseSheet extends StatefulWidget {
  final String tripId;

  const QuickExpenseSheet({super.key, required this.tripId});

  @override
  State<QuickExpenseSheet> createState() => _QuickExpenseSheetState();
}

class _QuickExpenseSheetState extends State<QuickExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  BudgetCategory _selectedCategory = BudgetCategory.food;

  static const _quickCategories = [
    BudgetCategory.food,
    BudgetCategory.transport,
    BudgetCategory.activity,
    BudgetCategory.other,
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottomInsets = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<QuickExpenseCubit, QuickExpenseState>(
      listener: (context, state) {
        if (state is QuickExpenseSaved) {
          AppHaptics.success();
          Navigator.of(context).pop();
        } else if (state is QuickExpenseError) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(toUserFriendlyMessage(state.error, l10n))),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: bottomInsets),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                // Title
                Text(
                  l10n.qaQuickExpenseTitle,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColorName.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                // Amount field
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.euro, size: 20),
                    hintText: l10n.qaQuickExpenseAmount,
                    hintStyle: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.qaQuickExpenseAmountRequired;
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return l10n.qaQuickExpenseInvalidAmount;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.space16),
                // Category chips
                Wrap(
                  spacing: AppSpacing.space8,
                  runSpacing: AppSpacing.space8,
                  children: _quickCategories.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return ChoiceChip(
                      label: Text(
                        _categoryLabel(cat, l10n),
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 13,
                          color: isSelected
                              ? ColorName.surface
                              : ColorName.primary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: ColorName.primary,
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      shape: const StadiumBorder(),
                      onSelected: (_) {
                        AppHaptics.light();
                        setState(() => _selectedCategory = cat);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.space16),
                // Note field
                TextField(
                  controller: _noteController,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.qaQuickExpenseNote,
                    hintStyle: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                // Done button
                BlocBuilder<QuickExpenseCubit, QuickExpenseState>(
                  builder: (context, state) {
                    final isSaving = state is QuickExpenseSaving;
                    return Container(
                      height: 52,
                      decoration: const BoxDecoration(
                        borderRadius: AppRadius.large16,
                        gradient: LinearGradient(
                          colors: [ColorName.primary, ColorName.secondary],
                        ),
                      ),
                      child: MaterialButton(
                        onPressed: isSaving ? null : _onSubmit,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.large16,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    ColorName.surface,
                                  ),
                                ),
                              )
                            : Text(
                                l10n.saveButton,
                                style: const TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: ColorName.surface,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.space24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text);
    context.read<QuickExpenseCubit>().saveExpense(
      tripId: widget.tripId,
      amount: amount,
      category: _selectedCategory,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
  }

  String _categoryLabel(BudgetCategory cat, AppLocalizations l10n) {
    return switch (cat) {
      BudgetCategory.food => l10n.qaCategoryFood,
      BudgetCategory.transport => l10n.qaCategoryTransport,
      BudgetCategory.activity => l10n.qaCategoryActivity,
      BudgetCategory.other => l10n.qaCategoryOther,
      _ => cat.name,
    };
  }
}
