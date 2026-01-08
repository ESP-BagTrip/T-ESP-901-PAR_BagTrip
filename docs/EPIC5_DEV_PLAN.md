# Epic 5: Client Trip & Traveler Management - Plan de Développement Complet

## 📋 Vue d'ensemble

**Objectif** : Créer les écrans et la logique pour gérer les trips et travelers côté client Flutter, permettant aux utilisateurs de créer un voyage et d'ajouter des accompagnants avant de commencer à planifier avec l'agent IA.

**Durée estimée** : 2-3 jours de développement

**Dépendances** : Epic 4 (services TripService et TravelerService doivent être fonctionnels)

**Livrables** :
- 1 écran modifié (HomePage avec bouton "Planifier un voyage IA")
- 2 nouveaux écrans (CreateTripPage, TravelersPage)
- 2 BLoC optionnels (TripBloc, TravelerBloc) si nécessaire
- Navigation complète entre les écrans
- Intégration avec les services existants

**Statut** : ✅ **IMPLÉMENTÉ**

---

## 🎯 Objectifs détaillés

1. **Modifier HomePage** : Ajouter un bouton pour lancer la planification de voyage IA
2. **Créer CreateTripPage** : Interface pour créer un nouveau trip avec nom
3. **Créer TravelersPage** : Interface pour gérer les travelers d'un trip
4. **Navigation** : Flux complet Home → CreateTrip → Travelers → Chat (préparation pour Epic 6)
5. **Gestion d'état** : Utiliser les services TripService et TravelerService créés dans Epic 4
6. **Validation** : Valider les formulaires avant soumission

---

## 📦 Structure des tâches

### Tâche 5.1 : Modifier HomePage pour ajouter le bouton "Planifier un voyage IA"
**Fichier** : `bagtrip/lib/pages/home_page.dart`

**Spécifications** :

Modifier la page d'accueil existante pour ajouter un bouton ou une carte permettant de lancer la planification de voyage IA.

```dart
// Dans home_page.dart, ajouter un bouton/carte
ElevatedButton.icon(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateTripPage(),
      ),
    );
  },
  icon: const Icon(Icons.auto_awesome),
  label: const Text('Planifier un voyage IA'),
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ),
)
```

**Critères d'acceptation** :
- ✅ Bouton visible et accessible sur HomePage
- ✅ Navigation vers CreateTripPage fonctionnelle
- ✅ Design cohérent avec l'UI existante
- ✅ Texte clair : "Planifier un voyage IA"

**Estimation** : 30 minutes

---

### Tâche 5.2 : Créer le modèle de données Conversation (si nécessaire)
**Fichier** : `bagtrip/lib/models/conversation.dart`

**Spécifications** :

Créer le modèle Conversation pour représenter une conversation liée à un trip.

```dart
class Conversation {
  final String id;
  final String tripId;
  final String userId;
  final String? title;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Conversation({
    required this.id,
    required this.tripId,
    required this.userId,
    this.title,
    required this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? json['trip_id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String,
      title: json['title'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'userId': userId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
```

**Critères d'acceptation** :
- ✅ Modèle créé avec tous les champs de l'API
- ✅ Support camelCase et snake_case
- ✅ Parsing des dates correct
- ✅ fromJson et toJson implémentés

**Estimation** : 20 minutes

---

### Tâche 5.3 : Créer le service de gestion des conversations
**Fichier** : `bagtrip/lib/service/conversation_service.dart`

**Spécifications** :

Créer un service pour gérer les conversations (création, récupération).

```dart
import 'package:bagtrip/models/conversation.dart';
import 'package:bagtrip/service/api_client.dart';

class ConversationService {
  final ApiClient _apiClient;

  ConversationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Créer une conversation pour un trip
  Future<Conversation> createConversation(
    String tripId, {
    String? title,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/conversations',
        data: {
          if (title != null) 'title': title,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Conversation.fromJson(response.data);
      } else {
        throw Exception('Failed to create conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating conversation: $e');
    }
  }

  /// Récupérer toutes les conversations d'un trip
  Future<List<Conversation>> getConversationsByTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/conversations');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => Conversation.fromJson(json)).toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => Conversation.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch conversations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching conversations: $e');
    }
  }

  /// Récupérer une conversation par ID
  Future<Conversation> getConversationById(String conversationId) async {
    try {
      final response = await _apiClient.get('/conversations/$conversationId');

      if (response.statusCode == 200) {
        return Conversation.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching conversation: $e');
    }
  }
}
```

**Critères d'acceptation** :
- ✅ Méthode createConversation implémentée
- ✅ Méthode getConversationsByTrip implémentée
- ✅ Méthode getConversationById implémentée
- ✅ Gestion d'erreurs appropriée
- ✅ Parsing des réponses correct

**Estimation** : 1h

---

### Tâche 5.4 : Créer l'écran CreateTripPage
**Fichier** : `bagtrip/lib/pages/create_trip_page.dart`

**Spécifications** :

Créer un écran avec un formulaire pour créer un nouveau trip.

```dart
import 'package:flutter/material.dart';
import 'package:bagtrip/service/trip_service.dart';
import 'package:bagtrip/service/conversation_service.dart';
import 'package:bagtrip/pages/travelers_page.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({Key? key}) : super(key: key);

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tripService = TripService();
  final _conversationService = ConversationService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Créer le trip
      final trip = await _tripService.createTrip(
        title: _titleController.text.trim(),
      );

      // Créer la conversation associée
      final conversation = await _conversationService.createConversation(
        trip.id,
        title: 'Planification ${trip.title}',
      );

      // Navigation vers TravelersPage
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TravelersPage(
              tripId: trip.id,
              conversationId: conversation.id,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau voyage'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Créez votre voyage',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Donnez un nom à votre voyage pour commencer la planification',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du voyage',
                    hintText: 'Ex: Vacances à Paris',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flight_takeoff),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un nom pour votre voyage';
                    }
                    if (value.trim().length < 3) {
                      return 'Le nom doit contenir au moins 3 caractères';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ),
                ],
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continuer'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Critères d'acceptation** :
- ✅ Formulaire avec champ nom du trip
- ✅ Validation du champ (non vide, min 3 caractères)
- ✅ Appel TripService.createTrip()
- ✅ Création automatique de la conversation
- ✅ Navigation vers TravelersPage avec tripId et conversationId
- ✅ Gestion du loading state
- ✅ Affichage des erreurs
- ✅ UI moderne et responsive

**Estimation** : 2h

---

### Tâche 5.5 : Créer l'écran TravelersPage
**Fichier** : `bagtrip/lib/pages/travelers_page.dart`

**Spécifications** :

Créer un écran pour gérer les travelers d'un trip (liste + formulaire d'ajout).

```dart
import 'package:flutter/material.dart';
import 'package:bagtrip/service/traveler_service.dart';
import 'package:bagtrip/models/traveler.dart';
import 'package:bagtrip/pages/chat_page.dart';
import 'package:intl/intl.dart';

class TravelersPage extends StatefulWidget {
  final String tripId;
  final String conversationId;

  const TravelersPage({
    Key? key,
    required this.tripId,
    required this.conversationId,
  }) : super(key: key);

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
      final travelers = await _travelerService.getTravelersByTrip(widget.tripId);
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
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le voyageur'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce voyageur ?'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voyageur supprimé')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleContinue() async {
    // Vérifier qu'il y a au moins un traveler
    if (_travelers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un voyageur'),
        ),
      );
      return;
    }

    // Navigation vers ChatPage
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            tripId: widget.tripId,
            conversationId: widget.conversationId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voyageurs'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Liste des travelers
                  Expanded(
                    child: _travelers.isEmpty
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
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ajoutez au moins un voyageur pour continuer',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[500],
                                      ),
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
                                  subtitle: traveler.dateOfBirth != null
                                      ? Text(
                                          'Né(e) le ${DateFormat('dd/MM/yyyy').format(traveler.dateOfBirth!)}',
                                        )
                                      : null,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _handleDeleteTraveler(traveler.id),
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
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
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
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
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
                            icon: _isAdding
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
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
```

**Critères d'acceptation** :
- ✅ Liste des travelers affichée
- ✅ Formulaire d'ajout de traveler (prénom, nom, date de naissance optionnelle)
- ✅ Validation des champs requis
- ✅ Sélecteur de date pour date de naissance
- ✅ Appel TravelerService.createTraveler()
- ✅ Suppression de traveler avec confirmation
- ✅ Bouton "Continuer" vers ChatPage
- ✅ Vérification qu'au moins un traveler est présent avant de continuer
- ✅ Gestion du loading state
- ✅ Affichage des erreurs
- ✅ UI moderne et responsive

**Estimation** : 3h

---

### Tâche 5.6 : Créer le BLoC TripBloc (optionnel)
**Fichier** : `bagtrip/lib/trip/bloc/trip_bloc.dart`

**Spécifications** :

Si nécessaire, créer un BLoC pour gérer l'état des trips (optionnel, les services peuvent suffire).

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/service/trip_service.dart';

// Events
abstract class TripEvent {}

class LoadTrips extends TripEvent {}
class CreateTrip extends TripEvent {
  final String title;
  final String? originIata;
  final String? destinationIata;
  final DateTime? startDate;
  final DateTime? endDate;

  CreateTrip({
    required this.title,
    this.originIata,
    this.destinationIata,
    this.startDate,
    this.endDate,
  });
}

// States
abstract class TripState {}

class TripInitial extends TripState {}
class TripLoading extends TripState {}
class TripLoaded extends TripState {
  final List<Trip> trips;

  TripLoaded(this.trips);
}
class TripError extends TripState {
  final String message;

  TripError(this.message);
}

// BLoC
class TripBloc extends Bloc<TripEvent, TripState> {
  final TripService _tripService;

  TripBloc({TripService? tripService})
      : _tripService = tripService ?? TripService(),
        super(TripInitial()) {
    on<LoadTrips>(_onLoadTrips);
    on<CreateTrip>(_onCreateTrip);
  }

  Future<void> _onLoadTrips(LoadTrips event, Emitter<TripState> emit) async {
    emit(TripLoading());
    try {
      final trips = await _tripService.getTrips();
      emit(TripLoaded(trips));
    } catch (e) {
      emit(TripError(e.toString()));
    }
  }

  Future<void> _onCreateTrip(CreateTrip event, Emitter<TripState> emit) async {
    emit(TripLoading());
    try {
      final trip = await _tripService.createTrip(
        title: event.title,
        originIata: event.originIata,
        destinationIata: event.destinationIata,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      // Recharger la liste
      add(LoadTrips());
    } catch (e) {
      emit(TripError(e.toString()));
    }
  }
}
```

**Critères d'acceptation** :
- ✅ BLoC créé avec events et states
- ✅ Gestion des erreurs
- ✅ Intégration avec TripService
- ✅ Optionnel : peut être omis si les services suffisent

**Estimation** : 1h30 (optionnel)

---

### Tâche 5.7 : Créer le BLoC TravelerBloc (optionnel)
**Fichier** : `bagtrip/lib/traveler/bloc/traveler_bloc.dart`

**Spécifications** :

Si nécessaire, créer un BLoC pour gérer l'état des travelers (optionnel).

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/models/traveler.dart';
import 'package:bagtrip/service/traveler_service.dart';

// Events
abstract class TravelerEvent {}

class LoadTravelers extends TravelerEvent {
  final String tripId;

  LoadTravelers(this.tripId);
}

class AddTraveler extends TravelerEvent {
  final String tripId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;

  AddTraveler({
    required this.tripId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
  });
}

class DeleteTraveler extends TravelerEvent {
  final String tripId;
  final String travelerId;

  DeleteTraveler({
    required this.tripId,
    required this.travelerId,
  });
}

// States
abstract class TravelerState {}

class TravelerInitial extends TravelerState {}
class TravelerLoading extends TravelerState {}
class TravelerLoaded extends TravelerState {
  final List<Traveler> travelers;

  TravelerLoaded(this.travelers);
}
class TravelerError extends TravelerState {
  final String message;

  TravelerError(this.message);
}

// BLoC
class TravelerBloc extends Bloc<TravelerEvent, TravelerState> {
  final TravelerService _travelerService;

  TravelerBloc({TravelerService? travelerService})
      : _travelerService = travelerService ?? TravelerService(),
        super(TravelerInitial()) {
    on<LoadTravelers>(_onLoadTravelers);
    on<AddTraveler>(_onAddTraveler);
    on<DeleteTraveler>(_onDeleteTraveler);
  }

  Future<void> _onLoadTravelers(
    LoadTravelers event,
    Emitter<TravelerState> emit,
  ) async {
    emit(TravelerLoading());
    try {
      final travelers = await _travelerService.getTravelersByTrip(event.tripId);
      emit(TravelerLoaded(travelers));
    } catch (e) {
      emit(TravelerError(e.toString()));
    }
  }

  Future<void> _onAddTraveler(
    AddTraveler event,
    Emitter<TravelerState> emit,
  ) async {
    emit(TravelerLoading());
    try {
      await _travelerService.createTraveler(
        event.tripId,
        firstName: event.firstName,
        lastName: event.lastName,
        dateOfBirth: event.dateOfBirth,
        gender: event.gender,
      );
      // Recharger la liste
      add(LoadTravelers(event.tripId));
    } catch (e) {
      emit(TravelerError(e.toString()));
    }
  }

  Future<void> _onDeleteTraveler(
    DeleteTraveler event,
    Emitter<TravelerState> emit,
  ) async {
    emit(TravelerLoading());
    try {
      await _travelerService.deleteTraveler(event.tripId, event.travelerId);
      // Recharger la liste
      add(LoadTravelers(event.tripId));
    } catch (e) {
      emit(TravelerError(e.toString()));
    }
  }
}
```

**Critères d'acceptation** :
- ✅ BLoC créé avec events et states
- ✅ Gestion des erreurs
- ✅ Intégration avec TravelerService
- ✅ Optionnel : peut être omis si les services suffisent

**Estimation** : 1h30 (optionnel)

---

## 📁 Structure des fichiers à créer/modifier

### Nouveaux fichiers

```
bagtrip/lib/
├── models/
│   └── conversation.dart                    [✅ CRÉÉ]
├── service/
│   └── conversation_service.dart             [✅ CRÉÉ]
├── pages/
│   ├── create_trip_page.dart                [✅ CRÉÉ]
│   ├── travelers_page.dart                  [✅ CRÉÉ]
│   └── chat_page.dart                       [✅ CRÉÉ - stub pour Epic 6]
└── trip/                                    [⚠️ OPTIONNEL - non implémenté]
    └── bloc/
        └── trip_bloc.dart                   [⚠️ OPTIONNEL - non implémenté]
└── traveler/                                [⚠️ OPTIONNEL - non implémenté]
    └── bloc/
        └── traveler_bloc.dart               [⚠️ OPTIONNEL - non implémenté]
```

### Fichiers à modifier

```
bagtrip/lib/
└── home/
    └── view/
        └── home_content.dart                 [✅ MODIFIÉ - bouton ajouté]
```

---

## 🔄 Flux de navigation

### Flow complet

```
1. HomePage
   → User clique sur "Planifier un voyage IA"
   → Navigation vers CreateTripPage

2. CreateTripPage
   → User saisit nom du trip
   → Submit → Création trip + conversation
   → Navigation vers TravelersPage (avec tripId et conversationId)

3. TravelersPage
   → User ajoute des travelers
   → User clique sur "Continuer"
   → Navigation vers ChatPage (Epic 6)
```

### Navigation avec paramètres

```dart
// CreateTripPage → TravelersPage
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => TravelersPage(
      tripId: trip.id,
      conversationId: conversation.id,
    ),
  ),
);

// TravelersPage → ChatPage
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => ChatPage(
      tripId: widget.tripId,
      conversationId: widget.conversationId,
    ),
  ),
);
```

---

## 🔒 Validation et gestion d'erreurs

### Validation des formulaires

**CreateTripPage** :
- Nom du trip : requis, minimum 3 caractères
- Affichage des erreurs de validation

**TravelersPage** :
- Prénom : requis
- Nom : requis
- Date de naissance : optionnelle
- Vérification qu'au moins un traveler est présent avant de continuer

### Gestion des erreurs

- **Erreurs réseau** : Afficher message clair à l'utilisateur
- **Erreurs API** : Afficher message d'erreur dans le formulaire
- **Erreurs de validation** : Afficher sous chaque champ concerné
- **Timeouts** : Gérer les timeouts avec message clair

---

## ✅ Checklist de validation

### Modèles
- [x] Conversation créé avec tous les champs
- [x] Support camelCase et snake_case dans fromJson
- [x] Méthodes toJson implémentées

### Services
- [x] ConversationService : create, getConversationsByTrip, getConversationById
- [x] Gestion d'erreurs dans ConversationService
- [x] Utilisation de TripService et TravelerService existants

### UI
- [x] HomePage modifiée avec bouton "Planifier un voyage IA"
- [x] CreateTripPage créée avec formulaire
- [x] TravelersPage créée avec liste et formulaire
- [x] Validation des formulaires
- [x] Affichage des erreurs
- [x] Loading states
- [x] Navigation fonctionnelle entre tous les écrans

### Intégration
- [x] Flux complet Home → CreateTrip → Travelers → Chat (préparation)
- [x] Création automatique de conversation lors de la création du trip
- [x] Passage des paramètres tripId et conversationId entre écrans

### Tests
- [ ] Test manuel : création d'un trip
- [ ] Test manuel : ajout de travelers
- [ ] Test manuel : suppression de traveler
- [ ] Test manuel : navigation complète
- [ ] Test manuel : validation des formulaires
- [ ] Test manuel : gestion des erreurs

---

## 🚀 Ordre d'exécution recommandé

1. ✅ **Tâche 5.1** : Modifier HomePage (ajouter bouton) - **TERMINÉ**
2. ✅ **Tâche 5.2** : Créer modèle Conversation - **TERMINÉ**
3. ✅ **Tâche 5.3** : Créer ConversationService - **TERMINÉ**
4. ✅ **Tâche 5.4** : Créer CreateTripPage - **TERMINÉ**
5. ✅ **Tâche 5.5** : Créer TravelersPage - **TERMINÉ**
6. ⚠️ **Tâche 5.6** : Créer TripBloc (optionnel) - **NON IMPLÉMENTÉ** (services suffisent)
7. ⚠️ **Tâche 5.7** : Créer TravelerBloc (optionnel) - **NON IMPLÉMENTÉ** (services suffisent)

---

## 📝 Notes importantes

### Dépendances requises

Si nécessaire, ajouter à `pubspec.yaml` :

```yaml
dependencies:
  intl: ^0.19.0  # Pour le formatage des dates
```

### Pattern de navigation

- **pushReplacement** : Utilisé pour remplacer l'écran actuel (pas de retour en arrière)
- **Paramètres** : Passer tripId et conversationId via le constructeur des pages
- **Navigation future** : ChatPage sera créée dans Epic 6

### Gestion d'état

- **Services directs** : Pour un POC, utiliser directement les services dans les StatefulWidget
- **BLoC optionnel** : Les BLoC peuvent être ajoutés si nécessaire pour une gestion d'état plus complexe
- **Recommandation POC** : Commencer avec les services directs, ajouter BLoC si besoin

### Création automatique de conversation

- Lors de la création d'un trip, créer automatiquement une conversation
- Titre par défaut : "Planification {nom du trip}"
- Cette conversation sera utilisée dans Epic 6 pour le chat

### Validation des travelers

- Au moins un traveler doit être présent avant de continuer vers le chat
- Afficher un message clair si l'utilisateur essaie de continuer sans travelers

---

## 🔗 Liens avec les épics suivants

- **Epic 6** : TravelersPage navigue vers ChatPage (à créer dans Epic 6)
- **Epic 6** : Les paramètres tripId et conversationId sont nécessaires pour le chat
- **Epic 7** : Les widgets du chat utiliseront les informations du trip et des travelers

---

## 📚 Références

- Services existants : `bagtrip/lib/service/trip_service.dart`, `traveler_service.dart` (Epic 4)
- Modèles existants : `bagtrip/lib/models/trip.dart`, `traveler.dart` (Epic 4)
- Pattern de pages : `bagtrip/lib/pages/login_page.dart` (Epic 4)
- API endpoints : Voir Epic 2 pour les endpoints conversations
- Navigation : `bagtrip/lib/navigation/app_router.dart`

---

**Date de création** : 2026-01-08
**Dernière mise à jour** : 2026-01-08
**Statut** : ✅ Implémenté
