import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/components/adaptive/adaptive_date_picker.dart';
import 'package:bagtrip/components/adaptive/adaptive_time_picker.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/design/widgets/form/item_form_primary_button.dart';
import 'package:bagtrip/design/widgets/form/micro_label_field.dart';
import 'package:bagtrip/design/widgets/form/pill_segmented_control.dart';
import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/design/widgets/item_status_chip.dart';
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

  /// Optional submission hook. When provided, the form invokes
  /// `onSave(data)` with the collected payload and the caller is
  /// responsible for dispatching (e.g. to `TripDetailBloc` from a panel).
  /// When `null`, falls back to the legacy behaviour on
  /// `AccommodationBloc`.
  final void Function(Map<String, dynamic> data)? onSave;

  const ManualAccommodationForm({
    super.key,
    required this.tripId,
    this.prefill,
    this.isEstimatedPrice = false,
    this.tripStartDate,
    this.tripEndDate,
    this.existing,
    this.onSave,
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

    if (widget.onSave != null) {
      widget.onSave!(data);
    } else if (_isEditMode) {
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

  ItemStatusChipKind? _statusKindFor(Accommodation? a) {
    if (a == null) return null;
    return ItemStatusChip.fromBackend(a.validationStatus.name.toUpperCase());
  }

  String _formatDate(DateTime? d) =>
      d != null ? DateFormat('dd/MM/yyyy').format(d) : '--/--/----';

  String _formatTime(TimeOfDay? t) => t != null
      ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
      : '--:--';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: ItemFormScaffold(
        title: _isEditMode
            ? l10n.accommodationEditTitle
            : l10n.accommodationAddManually,
        statusKind: _statusKindFor(widget.existing),
        fields: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FormSectionHeader(
              label: l10n.accommodationsTitle,
              icon: Icons.hotel_outlined,
            ),
            MicroLabelField(
              label: l10n.accommodationsTitle,
              controller: _nameCtrl,
              hint: 'Hotel Marriott, Airbnb…',
              validator: (v) => v == null || v.trim().isEmpty
                  ? l10n.activityTitleRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.space12),
            MicroLabelField(
              label: l10n.accommodationAddressLabel,
              controller: _addressCtrl,
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: ColorName.hint,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            FormSectionHeader(
              label: l10n.accommodationCheckInLabel,
              icon: Icons.date_range_outlined,
            ),
            Row(
              children: [
                Expanded(
                  child: MicroLabelField(
                    label: l10n.accommodationCheckInLabel,
                    readOnly: true,
                    displayValue: _formatDate(_checkIn),
                    onTap: () => _pickDate(isCheckIn: true),
                    errorText: _datesError,
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: ColorName.hint,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: MicroLabelField(
                    label: l10n.accommodationCheckInTimeLabel,
                    readOnly: true,
                    displayValue: _formatTime(_checkInTime),
                    onTap: () => _pickTime(isCheckIn: true),
                    suffixIcon: const Icon(
                      Icons.access_time,
                      size: 18,
                      color: ColorName.hint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),
            Row(
              children: [
                Expanded(
                  child: MicroLabelField(
                    label: l10n.accommodationCheckOutLabel,
                    readOnly: true,
                    displayValue: _formatDate(_checkOut),
                    onTap: () => _pickDate(isCheckIn: false),
                    errorText: _datesError != null ? ' ' : null,
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: ColorName.hint,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: MicroLabelField(
                    label: l10n.accommodationCheckOutTimeLabel,
                    readOnly: true,
                    displayValue: _formatTime(_checkOutTime),
                    onTap: () => _pickTime(isCheckIn: false),
                    suffixIcon: const Icon(
                      Icons.access_time,
                      size: 18,
                      color: ColorName.hint,
                    ),
                  ),
                ),
              ],
            ),
            if (_datesError != null && _datesError!.length > 1) ...[
              const SizedBox(height: AppSpacing.space4),
              Text(
                _datesError!,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 11,
                  color: ColorName.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space24),

            FormSectionHeader(
              label: l10n.accommodationPricePerNight,
              icon: Icons.payments_outlined,
            ),
            MicroLabelField(
              label: l10n.accommodationPricePerNight,
              controller: _priceCtrl,
              hint: '0',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(
                Icons.attach_money,
                size: 18,
                color: ColorName.hint,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            PillSegmentedControl<String>(
              value: _currency,
              compact: true,
              onChanged: (v) => setState(() => _currency = v),
              segments: const [
                PillSegmentOption(value: 'EUR', label: 'EUR'),
                PillSegmentOption(value: 'USD', label: 'USD'),
                PillSegmentOption(value: 'GBP', label: 'GBP'),
              ],
            ),
            if (widget.isEstimatedPrice) ...[
              const SizedBox(height: AppSpacing.space4),
              Text(
                l10n.accommodationEstimatedPrice,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 11,
                  color: ColorName.hint,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space24),

            FormSectionHeader(
              label: l10n.accommodationReferenceLabel,
              icon: Icons.confirmation_number_outlined,
            ),
            MicroLabelField(
              label: l10n.accommodationReferenceLabel,
              controller: _referenceCtrl,
              hint: l10n.fieldOptionalHint,
            ),
            const SizedBox(height: AppSpacing.space12),
            MicroLabelField(
              label: l10n.notesLabel,
              controller: _notesCtrl,
              hint: l10n.fieldOptionalHint,
              maxLines: 2,
              prefixIcon: const Icon(
                Icons.notes_outlined,
                size: 18,
                color: ColorName.hint,
              ),
            ),
          ],
        ),
        actions: [
          ItemFormPrimaryButton(
            label: _isEditMode ? l10n.accommodationSaveButton : l10n.addButton,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
