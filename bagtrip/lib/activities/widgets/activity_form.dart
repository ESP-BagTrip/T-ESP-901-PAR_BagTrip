import 'package:bagtrip/components/adaptive/adaptive_date_picker.dart';
import 'package:bagtrip/components/adaptive/adaptive_time_picker.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/form/form_choice_chips.dart';
import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/design/widgets/form/item_form_primary_button.dart';
import 'package:bagtrip/design/widgets/form/micro_label_field.dart';
import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/design/widgets/item_status_chip.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityForm extends StatefulWidget {
  final String tripId;
  final Activity? activity;
  final DateTime? initialDate;
  final void Function(Map<String, dynamic> data) onSave;

  const ActivityForm({
    super.key,
    required this.tripId,
    this.activity,
    this.initialDate,
    required this.onSave,
  });

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _costController;
  late DateTime _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late ActivityCategory _category;
  late bool _isBooked;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _titleController = TextEditingController(text: a?.title ?? '');
    _descriptionController = TextEditingController(text: a?.description ?? '');
    _locationController = TextEditingController(text: a?.location ?? '');
    _costController = TextEditingController(
      text: a?.estimatedCost != null
          ? a!.estimatedCost!.toStringAsFixed(2)
          : '',
    );
    _date = a?.date ?? widget.initialDate ?? DateTime.now();
    _startTime = a?.startTime != null ? _parseTime(a!.startTime!) : null;
    _endTime = a?.endTime != null ? _parseTime(a!.endTime!) : null;
    _category = a?.category ?? ActivityCategory.other;
    _isBooked = a?.isBooked ?? false;
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime != null && _endTime != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      if (endMinutes <= startMinutes) {
        AppSnackBar.showError(
          context,
          message: AppLocalizations.of(context)!.activityEndTimeBeforeStartTime,
        );
        return;
      }
    }
    final data = <String, dynamic>{
      'title': _titleController.text,
      'date': DateFormat('yyyy-MM-dd').format(_date),
      'category': _category.name.toUpperCase(),
      'isBooked': _isBooked,
      'validationStatus': 'MANUAL',
    };
    if (_descriptionController.text.isNotEmpty) {
      data['description'] = _descriptionController.text;
    }
    if (_locationController.text.isNotEmpty) {
      data['location'] = _locationController.text;
    }
    if (_costController.text.isNotEmpty) {
      data['estimatedCost'] = double.parse(_costController.text);
    }
    if (_startTime != null) data['startTime'] = _formatTime(_startTime!);
    if (_endTime != null) data['endTime'] = _formatTime(_endTime!);
    widget.onSave(data);
    Navigator.of(context).pop();
  }

  ItemStatusChipKind? _statusKindFor(Activity? a) {
    if (a == null) return null;
    return ItemStatusChip.fromBackend(a.validationStatus.name.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.activity != null;

    return Form(
      key: _formKey,
      child: ItemFormScaffold(
        title: isEdit ? l10n.activityFormEdit : l10n.activityFormNew,
        statusKind: _statusKindFor(widget.activity),
        fields: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FormSectionHeader(
              label: l10n.activityTitle,
              icon: Icons.event_outlined,
            ),
            MicroLabelField(
              label: l10n.activityTitle,
              controller: _titleController,
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.activityTitleRequired : null,
            ),
            const SizedBox(height: AppSpacing.space12),
            MicroLabelField(
              label: l10n.activityDescription,
              controller: _descriptionController,
              hint: l10n.fieldOptionalHint,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.space24),

            FormSectionHeader(
              label: l10n.activityStartTime,
              icon: Icons.schedule,
            ),
            MicroLabelField(
              label: l10n.expenseDate,
              readOnly: true,
              displayValue: DateFormat('dd/MM/yyyy').format(_date),
              onTap: () async {
                final picked = await showAdaptiveDatePicker(
                  context: context,
                  initialDate: _date,
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
            const SizedBox(height: AppSpacing.space12),
            Row(
              children: [
                Expanded(
                  child: MicroLabelField(
                    label: l10n.activityStartTime,
                    readOnly: true,
                    displayValue: _startTime != null
                        ? _formatTime(_startTime!)
                        : '--:--',
                    onTap: () async {
                      final picked = await showAdaptiveTimePicker(
                        context: context,
                        initialTime: _startTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _startTime = picked);
                    },
                    suffixIcon: const Icon(
                      Icons.access_time,
                      size: 18,
                      color: ColorName.hint,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: MicroLabelField(
                    label: l10n.activityEndTime,
                    readOnly: true,
                    displayValue: _endTime != null
                        ? _formatTime(_endTime!)
                        : '--:--',
                    onTap: () async {
                      final picked = await showAdaptiveTimePicker(
                        context: context,
                        initialTime: _endTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _endTime = picked);
                    },
                    suffixIcon: const Icon(
                      Icons.access_time,
                      size: 18,
                      color: ColorName.hint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space24),

            FormSectionHeader(
              label: l10n.activityLocation,
              icon: Icons.place_outlined,
            ),
            MicroLabelField(
              label: l10n.activityLocation,
              controller: _locationController,
              hint: l10n.fieldOptionalHint,
              prefixIcon: const Icon(
                Icons.place_outlined,
                size: 18,
                color: ColorName.hint,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            MicroLabelField(
              label: l10n.activityEstimatedCost,
              controller: _costController,
              hint: '0',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: const Icon(
                Icons.euro,
                size: 18,
                color: ColorName.hint,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            FormChoiceChips<ActivityCategory>(
              label: l10n.activityCategory,
              icon: Icons.category_outlined,
              value: _category,
              onChanged: (cat) {
                AppHaptics.light();
                setState(() => _category = cat);
              },
              options: [
                for (final cat in ActivityCategory.values)
                  FormChoiceChipOption(
                    value: cat,
                    label: cat.label(l10n),
                    icon: cat.icon,
                    iconColor: cat.color,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isBooked = !_isBooked),
                borderRadius: AppRadius.medium12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space12,
                    vertical: AppSpacing.space8,
                  ),
                  decoration: BoxDecoration(
                    color: ColorName.surfaceLight,
                    borderRadius: AppRadius.medium12,
                    border: Border.all(color: ColorName.border),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isBooked,
                        onChanged: (v) =>
                            setState(() => _isBooked = v ?? false),
                        activeColor: ColorName.secondary,
                      ),
                      Expanded(
                        child: Text(
                          l10n.activityFormBooked,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ColorName.primaryTrueDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ItemFormPrimaryButton(
            label: isEdit ? l10n.activityFormUpdate : l10n.activityFormCreate,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
