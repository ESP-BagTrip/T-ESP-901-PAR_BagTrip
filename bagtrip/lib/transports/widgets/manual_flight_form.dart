import 'package:bagtrip/components/adaptive/adaptive_date_picker.dart';
import 'package:bagtrip/components/adaptive/adaptive_time_picker.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:flutter/material.dart';

/// Inline form rendered inside the trip_detail flights panel (add / edit).
///
/// Caller-driven: [onSave] gets the collected payload and the caller is
/// responsible for dispatching it to the appropriate bloc
/// (usually `TripDetailBloc`). Keeping the form agnostic lets us drop the
/// legacy standalone `TransportsView` that previously hosted it.
class ManualFlightForm extends StatefulWidget {
  final String tripId;
  final ManualFlight? existing;
  final String? initialDepartureAirport;
  final String? initialArrivalAirport;
  final DateTime? initialDepartureDate;
  final DateTime? initialArrivalDate;
  final void Function(Map<String, dynamic> data) onSave;

  const ManualFlightForm({
    super.key,
    required this.tripId,
    required this.onSave,
    this.existing,
    this.initialDepartureAirport,
    this.initialArrivalAirport,
    this.initialDepartureDate,
    this.initialArrivalDate,
  });

  @override
  State<ManualFlightForm> createState() => _ManualFlightFormState();
}

class _ManualFlightFormState extends State<ManualFlightForm> {
  final _formKey = GlobalKey<FormState>();
  final _flightNumberCtrl = TextEditingController();
  final _airlineCtrl = TextEditingController();
  final _depAirportCtrl = TextEditingController();
  final _arrAirportCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _departureDate;
  DateTime? _arrivalDate;
  String _flightType = 'MAIN';
  String? _airportsError;
  String? _datesError;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final flight = widget.existing!;
      _flightNumberCtrl.text = flight.flightNumber;
      if (flight.airline != null) _airlineCtrl.text = flight.airline!;
      if (flight.departureAirport != null) {
        _depAirportCtrl.text = flight.departureAirport!;
      }
      if (flight.arrivalAirport != null) {
        _arrAirportCtrl.text = flight.arrivalAirport!;
      }
      _departureDate = flight.departureDate;
      _arrivalDate = flight.arrivalDate;
      if (flight.price != null) {
        _priceCtrl.text = flight.price!.toStringAsFixed(2);
      }
      if (flight.notes != null) _notesCtrl.text = flight.notes!;
      _flightType = flight.flightType;
    } else {
      if (widget.initialDepartureAirport != null) {
        _depAirportCtrl.text = widget.initialDepartureAirport!;
      }
      if (widget.initialArrivalAirport != null) {
        _arrAirportCtrl.text = widget.initialArrivalAirport!;
      }
      _departureDate = widget.initialDepartureDate;
      _arrivalDate = widget.initialArrivalDate;
    }
  }

  @override
  void dispose() {
    _flightNumberCtrl.dispose();
    _airlineCtrl.dispose();
    _depAirportCtrl.dispose();
    _arrAirportCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;

    // Clear previous custom errors
    setState(() {
      _airportsError = null;
      _datesError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    // Validate same airports
    final dep = _depAirportCtrl.text.toUpperCase().trim();
    final arr = _arrAirportCtrl.text.toUpperCase().trim();
    if (dep.isNotEmpty && arr.isNotEmpty && dep == arr) {
      setState(() => _airportsError = l10n.airportsMustDiffer);
      return;
    }

    // Validate arrival before departure
    if (_departureDate != null &&
        _arrivalDate != null &&
        _arrivalDate!.isBefore(_departureDate!)) {
      setState(() => _datesError = l10n.arrivalMustBeAfterDeparture);
      return;
    }

    final data = <String, dynamic>{
      'flightNumber': _flightNumberCtrl.text.toUpperCase().trim(),
      if (_airlineCtrl.text.isNotEmpty) 'airline': _airlineCtrl.text,
      if (_depAirportCtrl.text.isNotEmpty)
        'departureAirport': _depAirportCtrl.text.toUpperCase(),
      if (_arrAirportCtrl.text.isNotEmpty)
        'arrivalAirport': _arrAirportCtrl.text.toUpperCase(),
      if (_departureDate != null)
        'departureDate': _departureDate!.toIso8601String(),
      if (_arrivalDate != null) 'arrivalDate': _arrivalDate!.toIso8601String(),
      if (_priceCtrl.text.isNotEmpty) 'price': double.tryParse(_priceCtrl.text),
      'flightType': _flightType,
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text,
    };

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  Future<void> _pickDateTime({required bool isDeparture}) async {
    final now = DateTime.now();
    final date = await showAdaptiveDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    final time = await showAdaptiveTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isDeparture) {
        _departureDate = dt;
      } else {
        _arrivalDate = dt;
      }
      _datesError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final form = Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: ColorName.hint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditMode ? l10n.editFlight : l10n.addManuallyOption,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorName.primaryTrueDark,
                ),
              ),
              const SizedBox(height: 20),

              // ── Section 1 — Route ─────────────────────────────────
              _SectionLabel(label: l10n.routeSectionLabel),
              const SizedBox(height: 8),

              // Airports row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _depAirportCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.departureAirportLabel,
                        hintText: 'CDG',
                        errorText: _airportsError,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) {
                        if (_airportsError != null) {
                          setState(() => _airportsError = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _arrAirportCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.arrivalAirportLabel,
                        hintText: 'NRT',
                        errorText: _airportsError != null ? '' : null,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) {
                        if (_airportsError != null) {
                          setState(() => _airportsError = null);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Flight number
              TextFormField(
                controller: _flightNumberCtrl,
                decoration: InputDecoration(
                  labelText: l10n.flightNumberLabel,
                  hintText: 'AF1234',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v == null || v.trim().isEmpty
                    ? l10n.flightNumberRequired
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Section 2 — Schedule ──────────────────────────────
              _SectionLabel(label: l10n.scheduleSectionLabel),
              const SizedBox(height: 8),

              // Date pickers
              Row(
                children: [
                  Expanded(
                    child: _DatePickerTile(
                      label: l10n.departureDateLabel,
                      value: _departureDate,
                      onTap: () => _pickDateTime(isDeparture: true),
                      errorText: _datesError,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerTile(
                      label: l10n.arrivalDateLabel,
                      value: _arrivalDate,
                      onTap: () => _pickDateTime(isDeparture: false),
                      errorText: _datesError != null ? '' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Section 3 — Details ───────────────────────────────
              _SectionLabel(label: l10n.detailsSectionLabel),
              const SizedBox(height: 8),

              // Airline
              TextFormField(
                controller: _airlineCtrl,
                decoration: InputDecoration(labelText: l10n.airlineLabel),
              ),
              const SizedBox(height: 12),

              // Flight type
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'MAIN',
                    label: Text(l10n.mainFlightType),
                  ),
                  ButtonSegment(
                    value: 'INTERNAL',
                    label: Text(l10n.internalFlightType),
                  ),
                ],
                selected: {_flightType},
                onSelectionChanged: (v) =>
                    setState(() => _flightType = v.first),
              ),
              const SizedBox(height: 12),

              // Price
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: l10n.priceLabel,
                  suffixText: '\u20ac',
                ),
                keyboardType: TextInputType.number,
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
                  _isEditMode ? l10n.saveButton : l10n.addFlight,
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

    return form;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: FontFamily.b612,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ColorName.textMutedLight,
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? errorText;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.medium8,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
          errorText: errorText,
        ),
        child: Text(
          value != null
              ? '${value!.day}/${value!.month}/${value!.year} ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
              : '--/--/---- --:--',
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 14,
            color: value != null ? ColorName.primaryTrueDark : ColorName.hint,
          ),
        ),
      ),
    );
  }
}
