import 'package:bagtrip/components/adaptive/adaptive_date_picker.dart';
import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/adaptive/adaptive_indicator.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccommodationsPage extends StatefulWidget {
  final String tripId;
  final String role;
  final bool isCompleted;

  const AccommodationsPage({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  @override
  State<AccommodationsPage> createState() => _AccommodationsPageState();
}

class _AccommodationsPageState extends State<AccommodationsPage> {
  final _accommodationRepository = getIt<AccommodationRepository>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  List<Accommodation> _accommodations = [];
  bool _isLoading = true;
  bool _isAdding = false;
  String? _errorMessage;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  @override
  void initState() {
    super.initState();
    _loadAccommodations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAccommodations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _accommodationRepository.getByTrip(widget.tripId);
    switch (result) {
      case Success(:final data):
        setState(() {
          _accommodations = data;
          _isLoading = false;
        });
      case Failure(:final error):
        setState(() {
          _errorMessage = toUserFriendlyMessage(
            error,
            AppLocalizations.of(context)!,
          );
          _isLoading = false;
        });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isCheckIn
          ? AppLocalizations.of(context)!.accommodationCheckInHelp
          : AppLocalizations.of(context)!.accommodationCheckOutHelp,
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  Future<void> _handleAddAccommodation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    final priceText = _priceController.text.trim();
    final result = await _accommodationRepository.createAccommodation(
      widget.tripId,
      name: _nameController.text.trim(),
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      checkIn: _checkInDate,
      checkOut: _checkOutDate,
      pricePerNight: priceText.isNotEmpty ? double.tryParse(priceText) : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );
    switch (result) {
      case Success():
        _nameController.clear();
        _addressController.clear();
        _priceController.clear();
        _notesController.clear();
        _checkInDate = null;
        _checkOutDate = null;
        await _loadAccommodations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.accommodationAdded),
            ),
          );
        }
      case Failure(:final error):
        setState(() {
          _errorMessage = toUserFriendlyMessage(
            error,
            AppLocalizations.of(context)!,
          );
        });
    }
    setState(() {
      _isAdding = false;
    });
  }

  Future<void> _handleDeleteAccommodation(String accommodationId) async {
    showAdaptiveAlertDialog(
      context: context,
      title: AppLocalizations.of(context)!.accommodationDeleteTitle,
      content: AppLocalizations.of(context)!.accommodationDeleteConfirm,
      confirmLabel: AppLocalizations.of(context)!.deleteButton,
      cancelLabel: AppLocalizations.of(context)!.cancelButton,
      isDestructive: true,
      onConfirm: () async {
        final result = await _accommodationRepository.deleteAccommodation(
          widget.tripId,
          accommodationId,
        );
        switch (result) {
          case Success():
            await _loadAccommodations();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.accommodationDeleted,
                  ),
                ),
              );
            }
          case Failure(:final error):
            if (mounted) {
              AppSnackBar.showError(
                context,
                message: toUserFriendlyMessage(
                  error,
                  AppLocalizations.of(context)!,
                ),
              );
            }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isViewer = widget.role == 'VIEWER';
    final isReadOnly = isViewer || widget.isCompleted;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accommodationsTitle)),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AdaptiveIndicator())
            : Column(
                children: [
                  Expanded(
                    child: _accommodations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.hotel_outlined,
                                  size: 64,
                                  color: AppColors.hint,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.accommodationEmptyTitle,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: AppColors.hint),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.accommodationEmptySubtitle,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textMutedLight,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _accommodations.length,
                            itemBuilder: (context, index) {
                              final accommodation = _accommodations[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.hotel),
                                  ),
                                  title: Text(accommodation.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (accommodation.address != null)
                                        Text(accommodation.address!),
                                      if (accommodation.checkIn != null ||
                                          accommodation.checkOut != null)
                                        Text(
                                          '${accommodation.checkIn != null ? DateFormat('dd/MM/yyyy').format(accommodation.checkIn!) : '?'} → ${accommodation.checkOut != null ? DateFormat('dd/MM/yyyy').format(accommodation.checkOut!) : '?'}',
                                        ),
                                      if (accommodation.pricePerNight != null &&
                                          !isViewer)
                                        Text(
                                          '${accommodation.pricePerNight!.toStringAsFixed(2)} ${accommodation.currency ?? 'EUR'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: isReadOnly
                                      ? null
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          onPressed: () =>
                                              _handleDeleteAccommodation(
                                                accommodation.id,
                                              ),
                                        ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (!isReadOnly)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.accommodationAddTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nom *',
                                border: OutlineInputBorder(),
                                hintText: 'ex: Hotel Marriott Paris',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Requis';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Adresse (optionnel)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context, true),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText:
                                            l10n.accommodationCheckInLabel,
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(
                                          Icons.calendar_today,
                                        ),
                                      ),
                                      child: Text(
                                        _checkInDate != null
                                            ? DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(_checkInDate!)
                                            : '',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context, false),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText:
                                            l10n.accommodationCheckOutLabel,
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(
                                          Icons.calendar_today,
                                        ),
                                      ),
                                      child: Text(
                                        _checkOutDate != null
                                            ? DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(_checkOutDate!)
                                            : '',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Prix / nuit (optionnel)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.euro),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: ColorName.errorDark,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _isAdding
                                  ? null
                                  : _handleAddAccommodation,
                              icon: _isAdding
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator.adaptive(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add),
                              label: Text(l10n.addButton),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
