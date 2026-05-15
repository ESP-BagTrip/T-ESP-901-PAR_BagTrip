import 'package:bagtrip/components/adaptive/adaptive_date_picker.dart';
import 'package:bagtrip/components/adaptive/adaptive_time_picker.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/design/widgets/form/item_form_primary_button.dart';
import 'package:bagtrip/design/widgets/form/micro_label_field.dart';
import 'package:bagtrip/design/widgets/form/pill_dual_segment.dart';
import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/design/widgets/item_status_chip.dart';
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
  static const _datePlaceholder = '--/-- --:--';

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
        _priceCtrl.text = flight.price!.toStringAsFixed(0);
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _airportsError = null;
      _datesError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final dep = _depAirportCtrl.text.toUpperCase().trim();
    final arr = _arrAirportCtrl.text.toUpperCase().trim();
    if (dep.isNotEmpty && arr.isNotEmpty && dep == arr) {
      setState(() => _airportsError = l10n.airportsMustDiffer);
      return;
    }

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

  ItemStatusChipKind? _statusKindFor(ManualFlight? f) {
    if (f == null) return null;
    return ItemStatusChip.fromBackend(f.validationStatus.name.toUpperCase());
  }

  Widget _fieldIcon(IconData icon) {
    return Icon(icon, size: 18, color: ColorName.hint);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: ItemFormScaffold(
        title: _isEditMode ? l10n.editFlight : l10n.addFlight,
        statusKind: _statusKindFor(widget.existing),
        fields: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FormSectionHeader(
              label: l10n.routeSectionLabel,
              icon: Icons.alt_route,
            ),
            Row(
              children: [
                Expanded(
                  child: MicroLabelField(
                    label: l10n.departureAirportLabel,
                    controller: _depAirportCtrl,
                    hint: 'CDG',
                    textCapitalization: TextCapitalization.characters,
                    errorText: _airportsError,
                    onChanged: (_) {
                      if (_airportsError != null) {
                        setState(() => _airportsError = null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: MicroLabelField(
                    label: l10n.arrivalAirportLabel,
                    controller: _arrAirportCtrl,
                    hint: 'KEF',
                    textCapitalization: TextCapitalization.characters,
                    errorText: _airportsError != null ? ' ' : null,
                    onChanged: (_) {
                      if (_airportsError != null) {
                        setState(() => _airportsError = null);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),
            MicroLabelField(
              label: l10n.flightNumberLabel,
              controller: _flightNumberCtrl,
              hint: 'AF 123',
              prefixIcon: _fieldIcon(Icons.flight),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => v == null || v.trim().isEmpty
                  ? l10n.flightNumberRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.space24),

            FormSectionHeader(
              label: l10n.scheduleSectionLabel,
              icon: Icons.schedule,
            ),
            Row(
              children: [
                Expanded(
                  child: MicroLabelField(
                    label: l10n.departureAirportLabel,
                    readOnly: true,
                    displayValue: _departureDate != null
                        ? _formatDateTime(_departureDate!)
                        : _datePlaceholder,
                    onTap: () => _pickDateTime(isDeparture: true),
                    errorText: _datesError,
                    suffixIcon: _fieldIcon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: MicroLabelField(
                    label: l10n.arrivalAirportLabel,
                    readOnly: true,
                    displayValue: _arrivalDate != null
                        ? _formatDateTime(_arrivalDate!)
                        : _datePlaceholder,
                    onTap: () => _pickDateTime(isDeparture: false),
                    errorText: _datesError != null ? ' ' : null,
                    suffixIcon: _fieldIcon(Icons.calendar_today_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space24),

            FormSectionHeader(
              label: l10n.detailsSectionLabel,
              icon: Icons.layers_outlined,
            ),
            MicroLabelField(
              label: l10n.airlineLabel,
              controller: _airlineCtrl,
              hint: 'Air France, EasyJet…',
              prefixIcon: _fieldIcon(Icons.layers_outlined),
            ),
            const SizedBox(height: AppSpacing.space12),
            PillDualSegment<String>(
              value: _flightType,
              onChanged: (v) => setState(() => _flightType = v),
              segments: [
                PillDualSegmentOption(
                  value: 'MAIN',
                  label: l10n.mainFlightType,
                ),
                PillDualSegmentOption(
                  value: 'INTERNAL',
                  label: l10n.internalFlightType,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),
            Row(
              children: [
                Expanded(
                  child: MicroLabelField(
                    label: l10n.priceLabel,
                    controller: _priceCtrl,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    prefixIcon: _fieldIcon(Icons.attach_money),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.space4),
                      child: Text(
                        '€',
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorName.primaryTrueDark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: MicroLabelField(
                    label: l10n.notesLabel,
                    controller: _notesCtrl,
                    hint: l10n.fieldOptionalHint,
                    prefixIcon: _fieldIcon(Icons.chat_bubble_outline),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ItemFormPrimaryButton(
            label: _isEditMode ? l10n.saveButton : l10n.addFlight,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
