import 'package:bagtrip/components/adaptive/adaptive_date_picker.dart';
import 'package:bagtrip/components/adaptive/adaptive_time_picker.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
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

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

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
  }

  IconData _categoryIcon(ActivityCategory cat) {
    return switch (cat) {
      ActivityCategory.culture => Icons.museum_outlined,
      ActivityCategory.nature => Icons.park_outlined,
      ActivityCategory.food => Icons.restaurant_outlined,
      ActivityCategory.sport => Icons.fitness_center_outlined,
      ActivityCategory.shopping => Icons.shopping_bag_outlined,
      ActivityCategory.nightlife => Icons.nightlife_outlined,
      ActivityCategory.relaxation => Icons.spa_outlined,
      ActivityCategory.other => Icons.event_outlined,
    };
  }

  Color _categoryColor(ActivityCategory cat) {
    return switch (cat) {
      ActivityCategory.culture => const Color(0xFF5C6BC0),
      ActivityCategory.nature => const Color(0xFF66BB6A),
      ActivityCategory.food => const Color(0xFFFF7043),
      ActivityCategory.sport => const Color(0xFF42A5F5),
      ActivityCategory.shopping => const Color(0xFFAB47BC),
      ActivityCategory.nightlife => const Color(0xFF7E57C2),
      ActivityCategory.relaxation => const Color(0xFF26A69A),
      ActivityCategory.other => Colors.grey,
    };
  }

  String _categoryLabel(AppLocalizations l10n, ActivityCategory cat) {
    return switch (cat) {
      ActivityCategory.culture => l10n.categoryCulture,
      ActivityCategory.nature => l10n.categoryNature,
      ActivityCategory.food => l10n.categoryFoodDrink,
      ActivityCategory.sport => l10n.categorySport,
      ActivityCategory.shopping => l10n.categoryShopping,
      ActivityCategory.nightlife => l10n.categoryNightlife,
      ActivityCategory.relaxation => l10n.categoryRelaxation,
      ActivityCategory.other => l10n.categoryOtherActivity,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space16,
        right: AppSpacing.space16,
        top: AppSpacing.space16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.activity != null
                    ? l10n.activityFormEdit
                    : l10n.activityFormNew,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.space16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '${l10n.activityTitle} *',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? l10n.activityTitleRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.space12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${DateFormat('dd/MM/yyyy').format(_date)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showAdaptiveDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.activityDescription,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.space12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _startTime != null
                            ? 'Start: ${_formatTime(_startTime!)}'
                            : l10n.activityStartTime,
                      ),
                      onTap: () async {
                        final picked = await showAdaptiveTimePicker(
                          context: context,
                          initialTime: _startTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => _startTime = picked);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _endTime != null
                            ? 'End: ${_formatTime(_endTime!)}'
                            : l10n.activityEndTime,
                      ),
                      onTap: () async {
                        final picked = await showAdaptiveTimePicker(
                          context: context,
                          initialTime: _endTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => _endTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: l10n.activityLocation,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
              // Category chips
              Text(
                l10n.activityCategory,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ActivityCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  final color = _categoryColor(cat);
                  return ChoiceChip(
                    avatar: Icon(
                      _categoryIcon(cat),
                      size: 18,
                      color: isSelected ? Colors.white : color,
                    ),
                    label: Text(_categoryLabel(l10n, cat)),
                    selected: isSelected,
                    selectedColor: color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                    onSelected: (_) {
                      AppHaptics.light();
                      setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.space12),
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(
                  labelText: '${l10n.activityEstimatedCost} (\u20ac)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.euro),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
              CheckboxListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.activityFormBooked),
                value: _isBooked,
                onChanged: (v) => setState(() => _isBooked = v ?? false),
              ),
              const SizedBox(height: AppSpacing.space16),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  widget.activity != null
                      ? l10n.activityFormUpdate
                      : l10n.activityFormCreate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
