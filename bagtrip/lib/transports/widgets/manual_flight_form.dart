import 'dart:async';

import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/flight_info.dart';
import 'package:bagtrip/transports/bloc/transport_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManualFlightForm extends StatefulWidget {
  final String tripId;

  const ManualFlightForm({super.key, required this.tripId});

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
  Timer? _debounce;
  FlightInfo? _lookupInfo;
  bool _isLookingUp = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _flightNumberCtrl.dispose();
    _airlineCtrl.dispose();
    _depAirportCtrl.dispose();
    _arrAirportCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onFlightNumberChanged(String value) {
    _debounce?.cancel();
    final code = value.toUpperCase().trim();
    if (code.length >= 4) {
      _debounce = Timer(const Duration(milliseconds: 800), () {
        context.read<TransportBloc>().add(LookupFlightInfo(flightNumber: code));
      });
    }
  }

  void _applyLookup(FlightInfo info) {
    setState(() {
      _lookupInfo = info;
      if (info.airlineName != null) _airlineCtrl.text = info.airlineName!;
      if (info.departureIata != null) {
        _depAirportCtrl.text = info.departureIata!;
      }
      if (info.arrivalIata != null) _arrAirportCtrl.text = info.arrivalIata!;
      if (info.departureTime != null) {
        _departureDate = DateTime.tryParse(info.departureTime!);
      }
      if (info.arrivalTime != null) {
        _arrivalDate = DateTime.tryParse(info.arrivalTime!);
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

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

    context.read<TransportBloc>().add(
      CreateManualFlight(tripId: widget.tripId, data: data),
    );
    Navigator.of(context).pop();
  }

  Future<void> _pickDateTime({required bool isDeparture}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<TransportBloc, TransportState>(
      listener: (context, state) {
        if (state is FlightLookupLoading) {
          setState(() => _isLookingUp = true);
        } else if (state is FlightLookupLoaded) {
          setState(() => _isLookingUp = false);
          _applyLookup(state.info);
        } else if (state is FlightLookupError) {
          setState(() => _isLookingUp = false);
        }
      },
      child: Container(
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
                  l10n.addManuallyOption,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorName.primaryTrueDark,
                  ),
                ),
                const SizedBox(height: 20),

                // Flight number + lookup indicator
                TextFormField(
                  controller: _flightNumberCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.flightNumberLabel,
                    hintText: 'AF1234',
                    suffixIcon: _isLookingUp
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _lookupInfo != null
                        ? const Icon(
                            Icons.check_circle,
                            color: ColorName.success,
                          )
                        : null,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: _onFlightNumberChanged,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10n.flightNumberRequired
                      : null,
                ),
                const SizedBox(height: 12),

                // Airline
                TextFormField(
                  controller: _airlineCtrl,
                  decoration: InputDecoration(labelText: l10n.airlineLabel),
                ),
                const SizedBox(height: 12),

                // Airports row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _depAirportCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.departureAirportLabel,
                          hintText: 'CDG',
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _arrAirportCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.arrivalAirportLabel,
                          hintText: 'NRT',
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date pickers
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerTile(
                        label: l10n.departureDateLabel,
                        value: _departureDate,
                        onTap: () => _pickDateTime(isDeparture: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DatePickerTile(
                        label: l10n.arrivalDateLabel,
                        value: _arrivalDate,
                        onTap: () => _pickDateTime(isDeparture: false),
                      ),
                    ),
                  ],
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
                    l10n.addFlight,
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
