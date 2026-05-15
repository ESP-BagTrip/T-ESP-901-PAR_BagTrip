import 'package:bagtrip/components/adaptive/adaptive_date_picker.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/form/form_choice_chips.dart';
import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/design/widgets/form/item_form_primary_button.dart';
import 'package:bagtrip/design/widgets/form/micro_label_field.dart';
import 'package:bagtrip/design/widgets/form/pill_segmented_control.dart';
import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/design/widgets/item_status_chip.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';
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

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

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
    Navigator.of(context).pop();
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
            FormSectionHeader(label: l10n.expenseCategory, icon: Icons.tune),
            PillSegmentedControl<bool>(
              value: _isPlanned,
              onChanged: (v) {
                AppHaptics.light();
                setState(() => _isPlanned = v);
              },
              segments: [
                PillSegmentOption(value: true, label: l10n.expensePlanned),
                PillSegmentOption(value: false, label: l10n.expenseReal),
              ],
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
            const SizedBox(height: AppSpacing.space24),

            FormSectionHeader(
              label: l10n.expenseLabel,
              icon: Icons.receipt_long_outlined,
            ),
            MicroLabelField(
              label: l10n.expenseLabel,
              controller: _labelController,
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.expenseLabelRequired : null,
            ),
            const SizedBox(height: AppSpacing.space12),
            MicroLabelField(
              label: l10n.expenseAmount,
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: const Icon(
                Icons.euro,
                size: 18,
                color: ColorName.hint,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.fieldRequired;
                if (double.tryParse(v) == null) return l10n.fieldRequired;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.space24),

            FormChoiceChips<BudgetCategory>(
              label: l10n.expenseCategory,
              icon: Icons.category_outlined,
              value: _category,
              onChanged: (cat) {
                AppHaptics.light();
                setState(() => _category = cat);
              },
              options: [
                for (final cat in BudgetCategory.values)
                  FormChoiceChipOption(
                    value: cat,
                    label: cat.label(l10n),
                    icon: cat.icon,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space24),

            FormSectionHeader(
              label: l10n.expenseDate,
              icon: Icons.calendar_today_outlined,
            ),
            MicroLabelField(
              label: l10n.expenseDate,
              readOnly: true,
              displayValue: _date != null
                  ? _formatDate(_date!)
                  : l10n.fieldOptionalHint,
              onTap: () async {
                final picked = await showAdaptiveDatePicker(
                  context: context,
                  initialDate: _date ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: ColorName.hint,
              ),
            ),
          ],
        ),
        actions: [
          ItemFormPrimaryButton(label: l10n.saveButton, onPressed: _submit),
        ],
      ),
    );
  }
}
