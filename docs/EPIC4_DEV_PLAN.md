# Epic 4: Client Authentication & Core Infrastructure - Plan de Développement Complet

## 📋 Vue d'ensemble

**Objectif** : Créer l'infrastructure de base côté client Flutter : authentification, client API centralisé, stockage sécurisé, et services de base pour les trips, travelers et l'agent.

**Durée estimée** : 3-4 jours de développement

**Dépendances** : Epic 1, Epic 2, Epic 3 (API doit être fonctionnelle avec endpoints auth, trips, travelers, conversations, agent)

**Livrables** :
- 1 client API centralisé avec intercepteur JWT
- 5 services (auth, trip, traveler, agent, storage)
- 1 écran de login
- Modèles de données (User, Trip, Traveler, AuthResponse)
- Gestion du stockage sécurisé (JWT token)
- Navigation après authentification

**Statut** : ✅ **IMPLÉMENTÉ**

---

## 🎯 Objectifs détaillés

1. **Client API centralisé** : Créer un client Dio réutilisable avec intercepteur JWT et gestion d'erreurs
2. **Authentification** : Implémenter login, register, logout et stockage sécurisé du token
3. **Services métier** : Créer les services pour trips, travelers et agent
4. **Écran de login** : Créer l'interface utilisateur pour l'authentification
5. **Modèles de données** : Définir les modèles Dart pour User, Trip, Traveler, AuthResponse
6. **Navigation** : Gérer la navigation vers Home après login réussi
7. **Gestion d'état** : Intégrer l'authentification dans le flux de l'application

---

## 📦 Structure des tâches

### Tâche 4.1 : Créer le modèle de données User
**Fichier** : `bagtrip/lib/models/user.dart`

**Spécifications** :

```dart
class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? stripeCustomerId;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.stripeCustomerId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? json['full_name'] as String,
      phone: json['phone'] as String?,
      stripeCustomerId: json['stripeCustomerId'] as String? ?? json['stripe_customer_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'stripeCustomerId': stripeCustomerId,
    };
  }
}
```

**Critères d'acceptation** :
- ✅ Modèle créé avec tous les champs de l'API
- ✅ Support camelCase et snake_case (fromJson flexible)
- ✅ Méthodes fromJson et toJson implémentées
- ✅ Types corrects (String, String?)

**Estimation** : 30 minutes

---

### Tâche 4.2 : Créer le modèle de données AuthResponse
**Fichier** : `bagtrip/lib/models/auth_response.dart`

**Spécifications** :

```dart
class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}
```

**Critères d'acceptation** :
- ✅ Modèle créé avec token et user
- ✅ fromJson et toJson implémentés
- ✅ Types corrects

**Estimation** : 20 minutes

---

### Tâche 4.3 : Créer le modèle de données Trip
**Fichier** : `bagtrip/lib/models/trip.dart`

**Spécifications** :

```dart
enum TripStatus {
  draft,
  planning,
  booked,
  completed,
  cancelled;

  static TripStatus fromString(String value) {
    return TripStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => TripStatus.draft,
    );
  }
}

class Trip {
  final String id;
  final String userId;
  final String title;
  final String? originIata;
  final String? destinationIata;
  final DateTime? startDate;
  final DateTime? endDate;
  final TripStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Trip({
    required this.id,
    required this.userId,
    required this.title,
    this.originIata,
    this.destinationIata,
    this.startDate,
    this.endDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String,
      title: json['title'] as String,
      originIata: json['originIata'] as String? ?? json['origin_iata'] as String?,
      destinationIata: json['destinationIata'] as String? ?? json['destination_iata'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : json['start_date'] != null
              ? DateTime.parse(json['start_date'] as String)
              : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : json['end_date'] != null
              ? DateTime.parse(json['end_date'] as String)
              : null,
      status: TripStatus.fromString(
        json['status'] as String? ?? 'draft',
      ),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
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
      'userId': userId,
      'title': title,
      'originIata': originIata,
      'destinationIata': destinationIata,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
```

**Critères d'acceptation** :
- ✅ Modèle créé avec tous les champs de l'API
- ✅ Enum TripStatus pour le statut
- ✅ Support camelCase et snake_case
- ✅ Parsing des dates correct
- ✅ fromJson et toJson implémentés

**Estimation** : 45 minutes

---

### Tâche 4.4 : Créer le modèle de données Traveler
**Fichier** : `bagtrip/lib/models/traveler.dart`

**Spécifications** :

```dart
class Traveler {
  final String id;
  final String tripId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final Map<String, dynamic>? documents;
  final Map<String, dynamic>? contacts;

  Traveler({
    required this.id,
    required this.tripId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.documents,
    this.contacts,
  });

  factory Traveler.fromJson(Map<String, dynamic> json) {
    return Traveler(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? json['trip_id'] as String,
      firstName: json['firstName'] as String? ?? json['first_name'] as String,
      lastName: json['lastName'] as String? ?? json['last_name'] as String,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : json['date_of_birth'] != null
              ? DateTime.parse(json['date_of_birth'] as String)
              : null,
      gender: json['gender'] as String?,
      documents: json['documents'] as Map<String, dynamic>?,
      contacts: json['contacts'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'documents': documents,
      'contacts': contacts,
    };
  }
}
```

**Critères d'acceptation** :
- ✅ Modèle créé avec tous les champs de l'API
- ✅ Support camelCase et snake_case
- ✅ Parsing des dates correct
- ✅ Support JSON pour documents et contacts
- ✅ fromJson et toJson implémentés

**Estimation** : 30 minutes

---

### Tâche 4.5 : Créer le service de stockage sécurisé
**Fichier** : `bagtrip/lib/service/storage_service.dart`

**Spécifications** :

Utiliser `flutter_secure_storage` ou `shared_preferences` pour stocker le token JWT.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // User data management (optional, for caching)
  Future<void> saveUser(User user) async {
    // Optionnel : stocker les données utilisateur en JSON
  }

  Future<User?> getUser() async {
    // Optionnel : récupérer les données utilisateur
    return null;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

**Dépendances** :
- Ajouter `flutter_secure_storage: ^9.0.0` à `pubspec.yaml`

**Critères d'acceptation** :
- ✅ Service créé avec méthodes save/get/delete token
- ✅ Utilise flutter_secure_storage pour sécurité
- ✅ Méthode clearAll pour logout
- ✅ Gestion d'erreurs appropriée

**Estimation** : 1h

---

### Tâche 4.6 : Créer le client API centralisé
**Fichier** : `bagtrip/lib/service/api_client.dart`

**Spécifications** :

```dart
import 'package:dio/dio.dart';
import 'package:bagtrip/service/storage_service.dart';

class ApiClient {
  late final Dio _dio;
  final String baseUrl;
  final StorageService _storageService;

  ApiClient({
    String? baseUrl,
    StorageService? storageService,
  })  : baseUrl = baseUrl ?? 'http://localhost:3000/v1',
        _storageService = storageService ?? StorageService() {
    _dio = Dio(BaseOptions(
      baseUrl: this.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Intercepteur pour ajouter le token JWT
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Gestion centralisée des erreurs
          if (error.response?.statusCode == 401) {
            // Token expiré ou invalide
            _storageService.deleteToken();
            // Optionnel : rediriger vers login
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Méthodes helper pour les requêtes
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  // Getter pour accès direct au Dio (si nécessaire)
  Dio get dio => _dio;
}
```

**Critères d'acceptation** :
- ✅ Client Dio configuré avec baseUrl
- ✅ Intercepteur pour ajouter token JWT automatiquement
- ✅ Gestion d'erreurs centralisée (401 → logout)
- ✅ Timeouts configurés
- ✅ Méthodes helper (get, post, patch, delete)
- ✅ Singleton ou instance partagée recommandée

**Estimation** : 2h

---

### Tâche 4.7 : Créer le service d'authentification
**Fichier** : `bagtrip/lib/service/auth_service.dart`

**Spécifications** :

```dart
import 'package:bagtrip/models/auth_response.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/storage_service.dart';

class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthService({
    ApiClient? apiClient,
    StorageService? storageService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storageService = storageService ?? StorageService();

  /// Login avec email et password
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        // Sauvegarder le token
        await _storageService.saveToken(authResponse.token);
        
        return authResponse;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  /// Register avec email, password et fullName
  Future<AuthResponse> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        // Sauvegarder le token
        await _storageService.saveToken(authResponse.token);
        
        return authResponse;
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during registration: $e');
    }
  }

  /// Récupérer l'utilisateur actuel
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Vérifier si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout
  Future<void> logout() async {
    await _storageService.clearAll();
  }
}
```

**Critères d'acceptation** :
- ✅ Méthode login implémentée
- ✅ Méthode register implémentée
- ✅ Méthode getCurrentUser implémentée
- ✅ Méthode isAuthenticated implémentée
- ✅ Méthode logout implémentée
- ✅ Token sauvegardé automatiquement après login/register
- ✅ Gestion d'erreurs appropriée

**Estimation** : 1h30

---

### Tâche 4.8 : Créer le service de gestion des trips
**Fichier** : `bagtrip/lib/service/trip_service.dart`

**Spécifications** :

```dart
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/service/api_client.dart';

class TripService {
  final ApiClient _apiClient;

  TripService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Créer un nouveau trip
  Future<Trip> createTrip({
    required String title,
    String? originIata,
    String? destinationIata,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips',
        data: {
          'title': title,
          if (originIata != null) 'originIata': originIata,
          if (destinationIata != null) 'destinationIata': destinationIata,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Trip.fromJson(response.data);
      } else {
        throw Exception('Failed to create trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating trip: $e');
    }
  }

  /// Récupérer tous les trips de l'utilisateur
  Future<List<Trip>> getTrips() async {
    try {
      final response = await _apiClient.get('/trips');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => Trip.fromJson(json)).toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => Trip.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch trips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching trips: $e');
    }
  }

  /// Récupérer un trip par ID
  Future<Trip> getTripById(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId');

      if (response.statusCode == 200) {
        return Trip.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching trip: $e');
    }
  }

  /// Mettre à jour un trip
  Future<Trip> updateTrip(String tripId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId',
        data: updates,
      );

      if (response.statusCode == 200) {
        return Trip.fromJson(response.data);
      } else {
        throw Exception('Failed to update trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating trip: $e');
    }
  }

  /// Supprimer un trip
  Future<void> deleteTrip(String tripId) async {
    try {
      final response = await _apiClient.delete('/trips/$tripId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting trip: $e');
    }
  }
}
```

**Critères d'acceptation** :
- ✅ Méthode createTrip implémentée
- ✅ Méthode getTrips implémentée
- ✅ Méthode getTripById implémentée
- ✅ Méthode updateTrip implémentée
- ✅ Méthode deleteTrip implémentée
- ✅ Gestion d'erreurs appropriée
- ✅ Parsing des réponses correct

**Estimation** : 1h30

---

### Tâche 4.9 : Créer le service de gestion des travelers
**Fichier** : `bagtrip/lib/service/traveler_service.dart`

**Spécifications** :

```dart
import 'package:bagtrip/models/traveler.dart';
import 'package:bagtrip/service/api_client.dart';

class TravelerService {
  final ApiClient _apiClient;

  TravelerService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Créer un traveler pour un trip
  Future<Traveler> createTraveler(
    String tripId, {
    required String firstName,
    required String lastName,
    DateTime? dateOfBirth,
    String? gender,
    Map<String, dynamic>? documents,
    Map<String, dynamic>? contacts,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/travelers',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
          if (gender != null) 'gender': gender,
          if (documents != null) 'documents': documents,
          if (contacts != null) 'contacts': contacts,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Traveler.fromJson(response.data);
      } else {
        throw Exception('Failed to create traveler: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating traveler: $e');
    }
  }

  /// Récupérer tous les travelers d'un trip
  Future<List<Traveler>> getTravelersByTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/travelers');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => Traveler.fromJson(json)).toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => Traveler.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch travelers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching travelers: $e');
    }
  }

  /// Mettre à jour un traveler
  Future<Traveler> updateTraveler(
    String tripId,
    String travelerId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/travelers/$travelerId',
        data: updates,
      );

      if (response.statusCode == 200) {
        return Traveler.fromJson(response.data);
      } else {
        throw Exception('Failed to update traveler: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating traveler: $e');
    }
  }

  /// Supprimer un traveler
  Future<void> deleteTraveler(String tripId, String travelerId) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/travelers/$travelerId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete traveler: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting traveler: $e');
    }
  }
}
```

**Critères d'acceptation** :
- ✅ Méthode createTraveler implémentée
- ✅ Méthode getTravelersByTrip implémentée
- ✅ Méthode updateTraveler implémentée
- ✅ Méthode deleteTraveler implémentée
- ✅ Gestion d'erreurs appropriée
- ✅ Parsing des réponses correct

**Estimation** : 1h30

---

### Tâche 4.10 : Créer le service de l'agent (stub pour Epic 6)
**Fichier** : `bagtrip/lib/service/agent_service.dart`

**Spécifications** :

Pour l'instant, créer un stub qui sera complété dans Epic 6 (Client Chat Interface).

```dart
import 'package:bagtrip/service/api_client.dart';

class AgentService {
  final ApiClient _apiClient;

  AgentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Chat avec l'agent (SSE streaming)
  /// TODO: Implémenter dans Epic 6
  Stream<Map<String, dynamic>> chat({
    required String tripId,
    required String conversationId,
    required String message,
    int? contextVersion,
  }) {
    // Stub - sera implémenté dans Epic 6 avec SSE client
    throw UnimplementedError('Chat SSE will be implemented in Epic 6');
  }

  /// Action rapide (SELECT/BOOK)
  /// TODO: Implémenter dans Epic 6
  Future<Map<String, dynamic>> action({
    required String tripId,
    required String conversationId,
    required Map<String, dynamic> action,
    int? contextVersion,
  }) async {
    try {
      final response = await _apiClient.post(
        '/agent/actions',
        data: {
          'tripId': tripId,
          'conversationId': conversationId,
          'action': action,
          if (contextVersion != null) 'contextVersion': contextVersion,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to execute action: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error executing action: $e');
    }
  }
}
```

**Critères d'acceptation** :
- ✅ Service créé avec structure de base
- ✅ Méthode action implémentée (JSON response)
- ✅ Méthode chat créée en stub (sera complétée dans Epic 6)
- ✅ Gestion d'erreurs appropriée

**Estimation** : 1h

---

### Tâche 4.11 : Créer l'écran de login
**Fichier** : `bagtrip/lib/pages/login_page.dart`

**Spécifications** :

```dart
import 'package:flutter/material.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/navigation/app_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isLoginMode = true; // true = login, false = register
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      if (_isLoginMode) {
        await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Pour register, on pourrait ajouter un champ fullName
        await _authService.register(
          _emailController.text.trim(),
          _passwordController.text,
          'User', // TODO: Ajouter champ fullName dans le formulaire
        );
      }

      // Navigation vers Home après login réussi
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
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
        title: Text(_isLoginMode ? 'Connexion' : 'Inscription'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isLoginMode ? 'Connexion' : 'Inscription',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(_isLoginMode ? 'Se connecter' : 'S\'inscrire'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                            _errorMessage = null;
                          });
                        },
                  child: Text(
                    _isLoginMode
                        ? 'Pas de compte ? S\'inscrire'
                        : 'Déjà un compte ? Se connecter',
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
```

**Critères d'acceptation** :
- ✅ Formulaire email/password créé
- ✅ Validation des champs
- ✅ Toggle login/register
- ✅ Appel AuthService.login/register
- ✅ Gestion du loading state
- ✅ Affichage des erreurs
- ✅ Navigation vers AppShell après login réussi
- ✅ UI moderne et responsive

**Estimation** : 2h30

---

### Tâche 4.12 : Intégrer l'authentification dans main.dart
**Fichier** : `bagtrip/lib/main.dart`

**Modifications** :

Vérifier si l'utilisateur est authentifié au démarrage et rediriger vers login si nécessaire.

```dart
import 'package:flutter/material.dart';
import 'package:bagtrip/navigation/app_shell.dart';
import 'package:bagtrip/pages/login_page.dart';
import 'package:bagtrip/service/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BagTrip',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isAuth = await _authService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _isAuthenticated ? const AppShell() : const LoginPage();
  }
}
```

**Critères d'acceptation** :
- ✅ Vérification de l'authentification au démarrage
- ✅ Redirection vers LoginPage si non authentifié
- ✅ Redirection vers AppShell si authentifié
- ✅ Loading state pendant la vérification
- ✅ Gestion des erreurs

**Estimation** : 1h

---

## 📁 Structure des fichiers à créer/modifier

### Nouveaux fichiers

```
bagtrip/lib/
├── models/
│   ├── user.dart                    [NOUVEAU]
│   ├── auth_response.dart           [NOUVEAU]
│   ├── trip.dart                    [NOUVEAU]
│   └── traveler.dart                [NOUVEAU]
├── service/
│   ├── api_client.dart              [NOUVEAU]
│   ├── auth_service.dart            [NOUVEAU]
│   ├── trip_service.dart            [NOUVEAU]
│   ├── traveler_service.dart         [NOUVEAU]
│   ├── agent_service.dart           [NOUVEAU]
│   └── storage_service.dart         [NOUVEAU]
└── pages/
    └── login_page.dart              [NOUVEAU]
```

### Fichiers à modifier

```
bagtrip/
├── lib/main.dart                    [MODIFIER - ajouter AuthWrapper]
└── pubspec.yaml                     [MODIFIER - ajouter flutter_secure_storage]
```

---

## 🔄 Flux de données

### Login

```
1. User saisit email/password dans LoginPage
   → Appel AuthService.login()

2. AuthService envoie POST /v1/auth/login
   → ApiClient ajoute automatiquement le token dans les headers (après login)

3. API retourne { token, user }

4. AuthService sauvegarde le token via StorageService

5. LoginPage navigue vers AppShell
   → main.dart vérifie isAuthenticated() et affiche AppShell
```

### Requête API authentifiée

```
1. Service (ex: TripService) appelle ApiClient.get('/trips')

2. ApiClient intercepte la requête
   → Récupère le token via StorageService
   → Ajoute header: Authorization: Bearer {token}

3. API valide le token et retourne les données

4. Service parse la réponse et retourne les modèles
```

### Logout

```
1. User clique sur logout
   → Appel AuthService.logout()

2. AuthService appelle StorageService.clearAll()
   → Supprime le token

3. Navigation vers LoginPage
   → main.dart détecte isAuthenticated() = false
```

---

## 🔒 Sécurité

### Stockage du token

- **flutter_secure_storage** : Utilise Keychain (iOS) et Keystore (Android) pour stocker le token de manière sécurisée
- **Pas de stockage en clair** : Ne jamais stocker le token dans SharedPreferences en clair

### Gestion des erreurs 401

- **Token expiré** : L'intercepteur ApiClient détecte les erreurs 401 et supprime automatiquement le token
- **Redirection** : Optionnel : rediriger vers LoginPage si token expiré

### Validation des données

- **Formulaire login** : Validation email et password côté client
- **Erreurs API** : Affichage clair des erreurs à l'utilisateur

---

## ✅ Checklist de validation

### Modèles
- [x] User créé avec tous les champs
- [x] AuthResponse créé
- [x] Trip créé avec enum TripStatus
- [x] Traveler créé
- [x] Support camelCase et snake_case dans fromJson
- [x] Méthodes toJson implémentées

### Services
- [x] StorageService créé avec flutter_secure_storage
- [x] ApiClient créé avec intercepteur JWT
- [x] AuthService : login, register, getCurrentUser, logout
- [x] TripService : create, getTrips, getTripById, update, delete
- [x] TravelerService : create, getTravelersByTrip, update, delete
- [x] AgentService : action (stub chat pour Epic 6)
- [x] Gestion d'erreurs dans tous les services

### UI
- [x] LoginPage créé avec formulaire
- [x] Toggle login/register fonctionnel
- [x] Validation des champs
- [x] Affichage des erreurs
- [x] Loading state
- [x] Navigation vers AppShell après login

### Intégration
- [x] main.dart modifié avec AuthWrapper (géré via router redirect)
- [x] Vérification authentification au démarrage
- [x] Redirection automatique login/AppShell
- [x] Dépendances ajoutées à pubspec.yaml

### Tests
- [ ] Test manuel : login avec credentials valides
- [ ] Test manuel : login avec credentials invalides
- [ ] Test manuel : register
- [ ] Test manuel : logout
- [ ] Test manuel : requête API avec token (ex: getTrips)
- [ ] Test manuel : token expiré (401) → redirection login

---

## 🚀 Ordre d'exécution recommandé

1. **Tâche 4.1** : Créer modèle User
2. **Tâche 4.2** : Créer modèle AuthResponse
3. **Tâche 4.3** : Créer modèle Trip
4. **Tâche 4.4** : Créer modèle Traveler
5. **Tâche 4.5** : Créer StorageService
6. **Tâche 4.6** : Créer ApiClient
7. **Tâche 4.7** : Créer AuthService
8. **Tâche 4.11** : Créer LoginPage
9. **Tâche 4.12** : Intégrer authentification dans main.dart
10. **Tâche 4.8** : Créer TripService
11. **Tâche 4.9** : Créer TravelerService
12. **Tâche 4.10** : Créer AgentService (stub)

---

## 📝 Notes importantes

### Configuration de la base URL

- **Développement** : `http://localhost:3000/v1` (ou `http://10.0.2.2:3000/v1` pour Android emulator)
- **Production** : Configurer via variables d'environnement ou fichier de config
- **Recommandation** : Créer un fichier `config.dart` pour gérer les URLs selon l'environnement

### Gestion des erreurs

- **Erreurs réseau** : Afficher message clair à l'utilisateur
- **Erreurs 401** : Supprimer token et rediriger vers login
- **Erreurs 404/500** : Afficher message d'erreur approprié
- **Timeouts** : Gérer les timeouts avec message clair

### Pattern de services

- **Singleton optionnel** : Les services peuvent être des singletons ou instanciés à chaque utilisation
- **Dependency Injection** : Pour les tests, permettre l'injection de ApiClient et StorageService
- **Réutilisabilité** : ApiClient est partagé entre tous les services

### Dépendances requises

Ajouter à `pubspec.yaml` :

```yaml
dependencies:
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
```

---

## 🔗 Liens avec les épics suivants

- **Epic 5** : Utilisera TripService et TravelerService pour créer les écrans de gestion de trips/travelers
- **Epic 6** : Complétera AgentService avec le client SSE et l'interface de chat
- **Epic 7** : Utilisera les services pour afficher les widgets dans le chat

---

## 📚 Références

- Pattern de services : `bagtrip/lib/service/LocationService.dart` (existant)
- Pattern BLoC : `bagtrip/lib/home/bloc/` (existant)
- Navigation : `bagtrip/lib/navigation/app_shell.dart` (existant)
- Dio documentation : https://pub.dev/packages/dio
- Flutter Secure Storage : https://pub.dev/packages/flutter_secure_storage
- API endpoints : Voir Epic 1, Epic 2, Epic 3 pour les contrats API

---

**Date de création** : 2026-01-08
**Dernière mise à jour** : 2026-01-08
**Statut** : ✅ Implémenté

---

## 📝 Notes d'implémentation

### Implémentation réalisée

Tous les composants d'Epic 4 ont été implémentés avec succès :

1. **Modèles** : Tous les modèles (User, AuthResponse, Trip, Traveler) créés avec support camelCase/snake_case
2. **Services** : Tous les services créés (StorageService, ApiClient, AuthService, TripService, TravelerService, AgentService)
3. **UI** : LoginPage créée avec formulaire, validation, toggle login/register
4. **Intégration** : Router mis à jour avec redirect basé sur l'authentification, dépendances ajoutées

### Détails techniques

- **Authentification** : Gérée via `go_router` redirect callback qui vérifie l'état d'authentification à chaque navigation
- **Stockage** : Utilisation de `flutter_secure_storage` pour le stockage sécurisé du JWT
- **API Client** : Intercepteur Dio qui ajoute automatiquement le token JWT et gère les erreurs 401
- **Navigation** : Route `/login` créée en dehors du ShellRoute pour éviter l'affichage de la barre de navigation

### Fichiers créés/modifiés

**Nouveaux fichiers** :
- `bagtrip/lib/models/user.dart`
- `bagtrip/lib/models/auth_response.dart`
- `bagtrip/lib/models/trip.dart`
- `bagtrip/lib/models/traveler.dart`
- `bagtrip/lib/service/storage_service.dart`
- `bagtrip/lib/service/api_client.dart`
- `bagtrip/lib/service/auth_service.dart`
- `bagtrip/lib/service/trip_service.dart`
- `bagtrip/lib/service/traveler_service.dart`
- `bagtrip/lib/service/agent_service.dart`
- `bagtrip/lib/pages/login_page.dart`

**Fichiers modifiés** :
- `bagtrip/lib/navigation/app_router.dart` (ajout route /login et redirect)
- `bagtrip/pubspec.yaml` (ajout flutter_secure_storage: ^9.0.0)
