import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ManualAccommodationForm extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic>? prefill;
  final bool isEstimatedPrice;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;

  const ManualAccommodationForm({
    super.key,
    required this.tripId,
    this.prefill,
    this.isEstimatedPrice = false,
    this.tripStartDate,
    this.tripEndDate,
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
  String _currency = 'EUR';

  @override
  void initState() {
    super.initState();
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
    // Pre-fill dates from trip if not already set
    _checkIn ??= widget.tripStartDate;
    _checkOut ??= widget.tripEndDate;
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
    final date = await showDatePicker(
      context: context,
      initialDate: now,
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
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (_checkIn != null)
        'checkIn': _checkIn!.toIso8601String().split('T').first,
      if (_checkOut != null)
        'checkOut': _checkOut!.toIso8601String().split('T').first,
      if (_priceCtrl.text.isNotEmpty)
        'pricePerNight': double.tryParse(_priceCtrl.text),
      if (_priceCtrl.text.isNotEmpty) 'currency': _currency,
      if (_referenceCtrl.text.trim().isNotEmpty)
        'bookingReference': _referenceCtrl.text.trim(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    context.read<AccommodationBloc>().add(
      CreateAccommodation(tripId: widget.tripId, data: data),
    );
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
                l10n.accommodationAddManually,
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
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              const SizedBox(height: 12),

              // Check-in / Check-out
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
                    child: _DatePickerTile(
                      label: l10n.accommodationCheckOutLabel,
                      value: _checkOut,
                      onTap: () => _pickDate(isCheckIn: false),
                    ),
                  ),
                ],
              ),
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
                decoration: const InputDecoration(labelText: 'Reference'),
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
                  l10n.addButton,
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
