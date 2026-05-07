import 'package:bagtrip/components/adaptive/adaptive_date_picker.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/design/widgets/item_status_chip.dart';
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

  ItemStatusChipKind? _statusKindFor(BudgetItem? i) {
    if (i == null) return null;
    return ItemStatusChip.fromBackend(i.validationStatus.name.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.item != null;

    return Form(
      key: _formKey,
      child: ItemFormScaffold(
        title: isEdit ? l10n.editExpense : l10n.addExpense,
        statusKind: _statusKindFor(widget.item),
        fields: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Phase 2 — friction #9: the Planned/Spent distinction now
            // sits at the TOP of the form with an inline helper text so
            // the user knows where their entry will land before they
            // type a single character.
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.expensePlanned)),
                ButtonSegment(value: false, label: Text(l10n.expenseReal)),
              ],
              selected: {_isPlanned},
              onSelectionChanged: (set) {
                AppHaptics.light();
                setState(() => _isPlanned = set.first);
              },
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              _isPlanned ? l10n.budgetPlannedHelper : l10n.budgetSpentHelper,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                color: ColorName.hint,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            TextFormField(
              controller: _labelController,
              style: const TextStyle(fontFamily: FontFamily.b612, fontSize: 14),
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
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: const TextStyle(fontFamily: FontFamily.b612, fontSize: 14),
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
            Text(
              l10n.expenseCategory,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
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
                      color: isSelected ? ColorName.surface : ColorName.primary,
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
          ],
        ),
        actions: [
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
        ],
      ),
    );
  }
}
