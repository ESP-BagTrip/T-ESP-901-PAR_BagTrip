import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/components/adaptive/adaptive_date_picker.dart';
import 'package:bagtrip/components/adaptive/adaptive_time_picker.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ManualAccommodationForm extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic>? prefill;
  final bool isEstimatedPrice;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;
  final Accommodation? existing;

  const ManualAccommodationForm({
    super.key,
    required this.tripId,
    this.prefill,
    this.isEstimatedPrice = false,
    this.tripStartDate,
    this.tripEndDate,
    this.existing,
  });

  @override
  State<ManualAccommodationForm> createState() =>
      _ManualAccommodationFormState();
}

class _ManualAccommodationFormState extends State<ManualAccommodationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _checkIn;
  DateTime? _checkOut;
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;
  String _currency = 'EUR';
  String? _datesError;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _addressCtrl.text = existing.address ?? '';
      if (existing.pricePerNight != null) {
        _priceCtrl.text = existing.pricePerNight!.toStringAsFixed(
          existing.pricePerNight! == existing.pricePerNight!.roundToDouble()
              ? 0
              : 2,
        );
      }
      _referenceCtrl.text = existing.bookingReference ?? '';
      _notesCtrl.text = existing.notes ?? '';
      _currency = existing.currency ?? 'EUR';
      _checkIn = existing.checkIn;
      _checkOut = existing.checkOut;
      if (existing.checkIn != null) {
        final t = TimeOfDay.fromDateTime(existing.checkIn!);
        if (t.hour != 0 || t.minute != 0) _checkInTime = t;
      }
      if (existing.checkOut != null) {
        final t = TimeOfDay.fromDateTime(existing.checkOut!);
        if (t.hour != 0 || t.minute != 0) _checkOutTime = t;
      }
    } else {
      final p = widget.prefill;
      if (p != null) {
        _nameCtrl.text = p['name'] as String? ?? '';
        _addressCtrl.text = p['address'] as String? ?? '';
        if (p['pricePerNight'] != null) {
          _priceCtrl.text = p['pricePerNight'].toString();
        }
        if (p['neighborhood'] != null && _addressCtrl.text.isEmpty) {
          _addressCtrl.text = p['neighborhood'] as String;
        }
        _currency = p['currency'] as String? ?? 'EUR';
      }
      _checkIn ??= widget.tripStartDate;
      _checkOut ??= widget.tripEndDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final current = isCheckIn ? _checkIn : _checkOut;
    final date = await showAdaptiveDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = date;
      } else {
        _checkOut = date;
      }
      _validateDates();
    });
  }

  Future<void> _pickTime({required bool isCheckIn}) async {
    final current = isCheckIn ? _checkInTime : _checkOutTime;
    final time = await showAdaptiveTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      if (isCheckIn) {
        _checkInTime = time;
      } else {
        _checkOutTime = time;
      }
      _validateDates();
    });
  }

  void _validateDates() {
    _datesError = null;
    if (_checkIn != null && _checkOut != null) {
      final fullCheckIn = _combineDateAndTime(_checkIn!, _checkInTime);
      final fullCheckOut = _combineDateAndTime(_checkOut!, _checkOutTime);
      if (fullCheckOut.isBefore(fullCheckIn)) {
        _datesError = AppLocalizations.of(
          context,
        )!.accommodationCheckOutBeforeCheckIn;
      }
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay? time) {
    if (time != null) {
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }
    return DateTime(date.year, date.month, date.day);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _validateDates();
    if (_datesError != null) return;

    final checkInFull = _checkIn != null
        ? _combineDateAndTime(_checkIn!, _checkInTime)
        : null;
    final checkOutFull = _checkOut != null
        ? _combineDateAndTime(_checkOut!, _checkOutTime)
        : null;

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (checkInFull != null) 'checkIn': checkInFull.toIso8601String(),
      if (checkOutFull != null) 'checkOut': checkOutFull.toIso8601String(),
      if (_priceCtrl.text.isNotEmpty)
        'pricePerNight': double.tryParse(_priceCtrl.text),
      if (_priceCtrl.text.isNotEmpty) 'currency': _currency,
      if (_referenceCtrl.text.trim().isNotEmpty)
        'bookingReference': _referenceCtrl.text.trim(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    if (_isEditMode) {
      context.read<AccommodationBloc>().add(
        UpdateAccommodation(
          tripId: widget.tripId,
          accommodationId: widget.existing!.id,
          data: data,
        ),
      );
    } else {
      context.read<AccommodationBloc>().add(
        CreateAccommodation(tripId: widget.tripId, data: data),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditMode
                    ? l10n.accommodationEditTitle
                    : l10n.accommodationAddManually,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // Name (required)
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: '${l10n.accommodationsTitle} *',
                  hintText: 'Hotel Marriott, Airbnb Le Marais...',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l10n.activityTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),

              // Address
              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: l10n.accommodationAddressLabel,
                ),
              ),
              const SizedBox(height: 12),

              // Check-in date + time
              Row(
                children: [
                  Expanded(
                    child: _DatePickerTile(
                      label: l10n.accommodationCheckInLabel,
                      value: _checkIn,
                      onTap: () => _pickDate(isCheckIn: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePickerTile(
                      label: l10n.accommodationCheckInTimeLabel,
                      value: _checkInTime,
                      onTap: () => _pickTime(isCheckIn: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Check-out date + time
              Row(
                children: [
                  Expanded(
                    child: _DatePickerTile(
                      label: l10n.accommodationCheckOutLabel,
                      value: _checkOut,
                      onTap: () => _pickDate(isCheckIn: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePickerTile(
                      label: l10n.accommodationCheckOutTimeLabel,
                      value: _checkOutTime,
                      onTap: () => _pickTime(isCheckIn: false),
                    ),
                  ),
                ],
              ),

              // Date validation error
              if (_datesError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _datesError!,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Price per night + currency
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.accommodationPricePerNight,
                        suffixText: _currency,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'EUR', label: Text('EUR')),
                      ButtonSegment(value: 'USD', label: Text('USD')),
                      ButtonSegment(value: 'GBP', label: Text('GBP')),
                    ],
                    selected: {_currency},
                    onSelectionChanged: (v) =>
                        setState(() => _currency = v.first),
                  ),
                ],
              ),
              if (widget.isEstimatedPrice) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.accommodationEstimatedPrice,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Booking reference
              TextFormField(
                controller: _referenceCtrl,
                decoration: InputDecoration(
                  labelText: l10n.accommodationReferenceLabel,
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(labelText: l10n.notesLabel),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Submit
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: ColorName.primary,
                ),
                child: Text(
                  _isEditMode ? l10n.accommodationSaveButton : l10n.addButton,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.medium8,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value != null
              ? DateFormat('dd/MM/yyyy').format(value!)
              : '--/--/----',
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 14,
            color: value != null
                ? theme.colorScheme.onSurface
                : theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.medium8,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time, size: 18),
        ),
        child: Text(
          value != null
              ? '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
              : '--:--',
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 14,
            color: value != null
                ? theme.colorScheme.onSurface
                : theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
