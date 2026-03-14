import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/service/accommodation_service.dart';
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
  final _accommodationService = AccommodationService();
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

    try {
      final accommodations = await _accommodationService.getByTrip(
        widget.tripId,
      );
      setState(() {
        _accommodations = accommodations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isCheckIn ? 'Date d\'arrivée' : 'Date de départ',
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

    try {
      final priceText = _priceController.text.trim();
      await _accommodationService.createAccommodation(
        widget.tripId,
        name: _nameController.text.trim(),
        address:
            _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
        checkIn: _checkInDate,
        checkOut: _checkOutDate,
        pricePerNight: priceText.isNotEmpty ? double.tryParse(priceText) : null,
        notes:
            _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
      );

      _nameController.clear();
      _addressController.clear();
      _priceController.clear();
      _notesController.clear();
      _checkInDate = null;
      _checkOutDate = null;

      await _loadAccommodations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hébergement ajouté avec succès')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  Future<void> _handleDeleteAccommodation(String accommodationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer l\'hébergement'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cet hébergement ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: ColorName.error),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _accommodationService.deleteAccommodation(
          widget.tripId,
          accommodationId,
        );
        await _loadAccommodations();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Hébergement supprimé')));
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, message: toUserFriendlyMessage(e));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isViewer = widget.role == 'VIEWER';
    final isReadOnly = isViewer || widget.isCompleted;

    return Scaffold(
      appBar: AppBar(title: const Text('Hébergements')),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Expanded(
                      child:
                          _accommodations.isEmpty
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
                                      'Aucun hébergement',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: AppColors.hint),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ajoutez vos hôtels et logements',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
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
                                          if (accommodation.pricePerNight !=
                                                  null &&
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
                                      trailing:
                                          isReadOnly
                                              ? null
                                              : IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                                onPressed:
                                                    () =>
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
                                'Ajouter un hébergement',
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
                                        decoration: const InputDecoration(
                                          labelText: 'Arrivée',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(
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
                                        decoration: const InputDecoration(
                                          labelText: 'Départ',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(
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
                                onPressed:
                                    _isAdding ? null : _handleAddAccommodation,
                                icon:
                                    _isAdding
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.add),
                                label: const Text('Ajouter'),
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
