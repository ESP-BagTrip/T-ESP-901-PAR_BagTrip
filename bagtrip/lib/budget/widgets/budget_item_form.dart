import 'package:bagtrip/components/adaptive/adaptive_date_picker.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BudgetItemForm extends StatefulWidget {
  final String tripId;
  final BudgetItem? item;
  final void Function(Map<String, dynamic> data) onSave;

  const BudgetItemForm({
    super.key,
    required this.tripId,
    this.item,
    required this.onSave,
  });

  @override
  State<BudgetItemForm> createState() => _BudgetItemFormState();
}

class _BudgetItemFormState extends State<BudgetItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _amountController;
  late DateTime? _date;
  late BudgetCategory _category;
  late bool _isPlanned;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _labelController = TextEditingController(text: item?.label ?? '');
    _amountController = TextEditingController(
      text: item != null ? item.amount.toStringAsFixed(2) : '',
    );
    _date = item?.date;
    _category = item?.category ?? BudgetCategory.other;
    _isPlanned = item?.isPlanned ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    AppHaptics.success();
    final data = <String, dynamic>{
      'label': _labelController.text,
      'amount': double.parse(_amountController.text),
      'category': _category.name.toUpperCase(),
      'isPlanned': _isPlanned,
    };
    if (_date != null) {
      data['date'] = DateFormat('yyyy-MM-dd').format(_date!);
    }
    widget.onSave(data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.space24,
        right: AppSpacing.space24,
        top: AppSpacing.space12,
        bottom: bottomInsets + AppSpacing.space16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                widget.item != null ? l10n.editExpense : l10n.addExpense,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Label field
              TextFormField(
                controller: _labelController,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: l10n.expenseLabel,
                  labelStyle: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 14,
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.expenseLabelRequired : null,
              ),
              const SizedBox(height: AppSpacing.space16),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: l10n.expenseAmount,
                  labelStyle: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 14,
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.euro, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.fieldRequired;
                  if (double.tryParse(v) == null) return l10n.fieldRequired;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space16),

              // Category label
              Text(
                l10n.expenseCategory,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),

              // Category chips
              Wrap(
                spacing: AppSpacing.space8,
                runSpacing: AppSpacing.space8,
                children: BudgetCategory.values.map((cat) {
                  final isSelected = cat == _category;
                  return ChoiceChip(
                    label: Text(
                      cat.label(l10n),
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
                      setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.space16),

              // Date picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _date != null
                      ? '${l10n.expenseDate}: ${DateFormat('dd/MM/yyyy').format(_date!)}'
                      : l10n.expenseDate,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today, size: 20),
                onTap: () async {
                  final picked = await showAdaptiveDatePicker(
                    context: context,
                    initialDate: _date ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: AppSpacing.space8),

              // Planned/Real toggle
              Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      l10n.expensePlanned,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: _isPlanned
                            ? ColorName.surface
                            : ColorName.primary,
                      ),
                    ),
                    selected: _isPlanned,
                    selectedColor: ColorName.primary,
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    shape: const StadiumBorder(),
                    onSelected: (_) {
                      AppHaptics.light();
                      setState(() => _isPlanned = true);
                    },
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  ChoiceChip(
                    label: Text(
                      l10n.expenseReal,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: !_isPlanned
                            ? ColorName.surface
                            : ColorName.primary,
                      ),
                    ),
                    selected: !_isPlanned,
                    selectedColor: ColorName.primary,
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    shape: const StadiumBorder(),
                    onSelected: (_) {
                      AppHaptics.light();
                      setState(() => _isPlanned = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space24),

              // Submit button — gradient
              Container(
                height: 52,
                decoration: const BoxDecoration(
                  borderRadius: AppRadius.large16,
                  gradient: LinearGradient(
                    colors: [ColorName.primary, ColorName.secondary],
                  ),
                ),
                child: MaterialButton(
                  onPressed: _submit,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.large16,
                  ),
                  child: Text(
                    l10n.saveButton,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorName.surface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
            ],
          ),
        ),
      ),
    );
  }
}
