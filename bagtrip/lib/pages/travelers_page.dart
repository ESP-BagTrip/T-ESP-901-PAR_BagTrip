import 'package:flutter/material.dart';
import 'package:bagtrip/service/traveler_service.dart';
import 'package:bagtrip/models/traveler.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TravelersPage extends StatefulWidget {
  final String tripId;
  final String conversationId;

  const TravelersPage({
    super.key,
    required this.tripId,
    required this.conversationId,
  });

  @override
  State<TravelersPage> createState() => _TravelersPageState();
}

class _TravelersPageState extends State<TravelersPage> {
  final _travelerService = TravelerService();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  List<Traveler> _travelers = [];
  bool _isLoading = true;
  bool _isAdding = false;
  String? _errorMessage;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadTravelers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _loadTravelers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final travelers = await _travelerService.getTravelersByTrip(
        widget.tripId,
      );
      setState(() {
        _travelers = travelers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Date de naissance',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleAddTraveler() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      await _travelerService.createTraveler(
        widget.tripId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _selectedDate,
        travelerType: 'ADULT', // Default traveler type
      );

      // Réinitialiser le formulaire
      _firstNameController.clear();
      _lastNameController.clear();
      _dateOfBirthController.clear();
      _selectedDate = null;

      // Recharger la liste
      await _loadTravelers();

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voyageur ajouté avec succès')),
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

  Future<void> _handleDeleteTraveler(String travelerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer le voyageur'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer ce voyageur ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _travelerService.deleteTraveler(widget.tripId, travelerId);
        await _loadTravelers();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Voyageur supprimé')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  Future<void> _handleContinue() async {
    // Vérifier qu'il y a au moins un traveler
    if (_travelers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un voyageur')),
      );
      return;
    }

    // Navigation vers ChatPage via router
    if (mounted) {
      context.go(
        '/chat?tripId=${widget.tripId}&conversationId=${widget.conversationId}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voyageurs')),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // Liste des travelers
                    Expanded(
                      child:
                          _travelers.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun voyageur',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ajoutez au moins un voyageur pour continuer',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _travelers.length,
                                itemBuilder: (context, index) {
                                  final traveler = _travelers[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          '${traveler.firstName[0]}${traveler.lastName[0]}',
                                        ),
                                      ),
                                      title: Text(
                                        '${traveler.firstName} ${traveler.lastName}',
                                      ),
                                      subtitle:
                                          traveler.dateOfBirth != null
                                              ? Text(
                                                'Né(e) le ${DateFormat('dd/MM/yyyy').format(traveler.dateOfBirth!)}',
                                              )
                                              : null,
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed:
                                            () => _handleDeleteTraveler(
                                              traveler.id,
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),

                    // Formulaire d'ajout
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ajouter un voyageur',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Prénom',
                                      border: OutlineInputBorder(),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Requis';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nom',
                                      border: OutlineInputBorder(),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Requis';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _dateOfBirthController,
                              decoration: const InputDecoration(
                                labelText: 'Date de naissance (optionnel)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(context),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[800]),
                              ),
                            ],
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _isAdding ? null : _handleAddTraveler,
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

                    // Bouton continuer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Continuer vers la planification'),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
