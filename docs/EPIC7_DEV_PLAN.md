# Epic 7: Client Widget System - Plan de Développement Complet

## 📋 Vue d'ensemble

**Objectif** : Créer le système de rendu de widgets dynamiques pilotés par le backend pour afficher des cartes interactives (vols, hôtels, itinéraires, avertissements) dans l'interface de chat.

**Durée estimée** : 3-4 jours de développement

**Dépendances** : 
- Epic 6 (ChatPage doit être fonctionnel, context.ui.widgets doit être disponible)
- Epic 3 (Backend doit envoyer les widgets dans context.ui)

**Livrables** :
- 1 widget renderer (factory pattern)
- 4 widgets individuels (FlightOfferCard, HotelOfferCard, ItinerarySummary, WarningWidget)
- Intégration dans ChatPage
- Gestion des actions (SELECT/BOOK)

**Statut** : ✅ **COMPLÉTÉ**

---

## 🎯 Objectifs détaillés

1. **Widget Renderer** : Créer un système de rendu dynamique basé sur le type de widget
2. **Widgets individuels** : Implémenter chaque type de widget avec un design cohérent
3. **Intégration Chat** : Remplacer le rendu basique actuel par le système de widgets
4. **Actions** : Gérer les actions sur les widgets (SELECT_FLIGHT, BOOK_FLIGHT, etc.)
5. **Extensibilité** : Créer un système facilement extensible pour de nouveaux types de widgets

---

## 📦 Structure des tâches

### Tâche 7.1 : Créer le Widget Renderer
**Fichier** : `bagtrip/lib/chat/widgets/widget_renderer.dart`

**Spécifications** :

Créer un widget factory qui rend le bon widget selon le type.

```dart
import 'package:flutter/material.dart';
import 'package:bagtrip/chat/models/context.dart';
import 'package:bagtrip/chat/widgets/flight_offer_card.dart';
import 'package:bagtrip/chat/widgets/hotel_offer_card.dart';
import 'package:bagtrip/chat/widgets/itinerary_summary.dart';
import 'package:bagtrip/chat/widgets/warning_widget.dart';

/// Widget factory pour rendre les widgets dynamiques selon leur type
class WidgetRenderer extends StatelessWidget {
  final WidgetData widgetData;
  final Function(String actionType, String? offerId)? onAction;

  const WidgetRenderer({
    Key? key,
    required this.widgetData,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (widgetData.type) {
      case 'FLIGHT_OFFER_CARD':
        return FlightOfferCard(
          widgetData: widgetData,
          onAction: onAction,
        );
      case 'HOTEL_OFFER_CARD':
        return HotelOfferCard(
          widgetData: widgetData,
          onAction: onAction,
        );
      case 'ITINERARY_SUMMARY':
        return ItinerarySummary(
          widgetData: widgetData,
          onAction: onAction,
        );
      case 'WARNING':
        return WarningWidget(
          widgetData: widgetData,
          onAction: onAction,
        );
      default:
        return _UnknownWidget(widgetData: widgetData);
    }
  }
}

/// Widget de fallback pour types inconnus
class _UnknownWidget extends StatelessWidget {
  final WidgetData widgetData;

  const _UnknownWidget({required this.widgetData});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Widget inconnu: ${widgetData.type}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (widgetData.title != null)
              Text(widgetData.title!),
          ],
        ),
      ),
    );
  }
}
```

**Critères d'acceptation** :
- ✅ Factory pattern implémenté
- ✅ Support de tous les types de widgets définis
- ✅ Fallback pour types inconnus
- ✅ Callback `onAction` pour gérer les actions
- ✅ Widget stateless et réutilisable

**Estimation** : 1h

---

### Tâche 7.2 : Créer FlightOfferCard
**Fichier** : `bagtrip/lib/chat/widgets/flight_offer_card.dart`

**Spécifications** :

Widget pour afficher une offre de vol avec informations principales et actions.

```dart
import 'package:flutter/material.dart';
import 'package:bagtrip/chat/models/context.dart';

class FlightOfferCard extends StatelessWidget {
  final WidgetData widgetData;
  final Function(String actionType, String? offerId)? onAction;

  const FlightOfferCard({
    Key? key,
    required this.widgetData,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Optionnel : action par défaut au tap
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec icône
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flight_takeoff,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widgetData.title != null)
                            Text(
                              widgetData.title!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (widgetData.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widgetData.subtitle!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Informations supplémentaires depuis data
                if (widgetData.data != null) ...[
                  const SizedBox(height: 12),
                  _buildDataInfo(widgetData.data!),
                ],

                const Spacer(),

                // Actions
                if (widgetData.actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widgetData.actions.map((action) {
                      return _buildActionButton(context, action);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataInfo(Map<String, dynamic> data) {
    final List<Widget> infoWidgets = [];

    if (data['departure'] != null) {
      infoWidgets.add(_buildInfoRow(
        Icons.flight_takeoff,
        'Départ',
        data['departure'] as String,
      ));
    }

    if (data['arrival'] != null) {
      infoWidgets.add(_buildInfoRow(
        Icons.flight_land,
        'Arrivée',
        data['arrival'] as String,
      ));
    }

    if (data['duration'] != null) {
      infoWidgets.add(_buildInfoRow(
        Icons.access_time,
        'Durée',
        data['duration'] as String,
      ));
    }

    if (data['stops'] != null) {
      infoWidgets.add(_buildInfoRow(
        Icons.layers,
        'Escales',
        '${data['stops']} escale(s)',
      ));
    }

    return Column(
      children: infoWidgets,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetAction action) {
    final isPrimary = action.type.contains('BOOK');
    final isSecondary = action.type.contains('SELECT');

    return ElevatedButton(
      onPressed: () {
        onAction?.call(action.type, widgetData.offerId);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        backgroundColor: isPrimary
            ? Theme.of(context).primaryColor
            : Colors.grey[200],
        foregroundColor: isPrimary
            ? Colors.white
            : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isPrimary ? 2 : 0,
      ),
      child: Text(
        action.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
```

**Critères d'acceptation** :
- ✅ Design cohérent avec Material Design
- ✅ Affichage des informations principales (title, subtitle)
- ✅ Affichage des données supplémentaires (departure, arrival, duration, stops)
- ✅ Actions cliquables (SELECT_FLIGHT, BOOK_FLIGHT)
- ✅ Responsive et adaptatif
- ✅ Icônes appropriées

**Estimation** : 2h

---

### Tâche 7.3 : Créer HotelOfferCard
**Fichier** : `bagtrip/lib/chat/widgets/hotel_offer_card.dart`

**Spécifications** :

Widget pour afficher une offre d'hôtel avec informations principales et actions.

```dart
import 'package:flutter/material.dart';
import 'package:bagtrip/chat/models/context.dart';

class HotelOfferCard extends StatelessWidget {
  final WidgetData widgetData;
  final Function(String actionType, String? offerId)? onAction;

  const HotelOfferCard({
    Key? key,
    required this.widgetData,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec icône
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.hotel,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widgetData.title != null)
                            Text(
                              widgetData.title!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (widgetData.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widgetData.subtitle!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Informations supplémentaires depuis data
                if (widgetData.data != null) ...[
                  const SizedBox(height: 12),
                  _buildDataInfo(widgetData.data!),
                ],

                const Spacer(),

                // Actions
                if (widgetData.actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widgetData.actions.map((action) {
                      return _buildActionButton(context, action);
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataInfo(Map<String, dynamic> data) {
    final List<Widget> infoWidgets = [];

    if (data['address'] != null) {
      infoWidgets.add(_buildInfoRow(
        Icons.location_on,
        'Adresse',
        data['address'] as String,
      ));
    }

    if (data['rating'] != null) {
      infoWidgets.add(_buildInfoRow(
        Icons.star,
        'Note',
        '${data['rating']}/5',
      ));
    }

    if (data['stars'] != null) {
      infoWidgets.add(_buildInfoRow(
        Icons.hotel,
        'Étoiles',
        '${data['stars']} étoiles',
      ));
    }

    if (data['amenities'] != null) {
      final amenities = data['amenities'] as List<dynamic>?;
      if (amenities != null && amenities.isNotEmpty) {
        infoWidgets.add(_buildInfoRow(
          Icons.check_circle,
          'Services',
          amenities.take(3).join(', '),
        ));
      }
    }

    return Column(
      children: infoWidgets,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetAction action) {
    final isPrimary = action.type.contains('BOOK');
    final isSecondary = action.type.contains('SELECT');

    return ElevatedButton(
      onPressed: () {
        onAction?.call(action.type, widgetData.offerId);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        backgroundColor: isPrimary
            ? Theme.of(context).primaryColor
            : Colors.grey[200],
        foregroundColor: isPrimary
            ? Colors.white
            : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isPrimary ? 2 : 0,
      ),
      child: Text(
        action.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
```

**Critères d'acceptation** :
- ✅ Design cohérent avec FlightOfferCard
- ✅ Affichage des informations hôtel (adresse, rating, stars, amenities)
- ✅ Actions cliquables (SELECT_HOTEL, BOOK_HOTEL)
- ✅ Icônes appropriées (hotel, location, star)

**Estimation** : 2h

---

### Tâche 7.4 : Créer ItinerarySummary
**Fichier** : `bagtrip/lib/chat/widgets/itinerary_summary.dart`

**Spécifications** :

Widget pour afficher un résumé d'itinéraire (vol + hôtel sélectionnés).

```dart
import 'package:flutter/material.dart';
import 'package:bagtrip/chat/models/context.dart';

class ItinerarySummary extends StatelessWidget {
  final WidgetData widgetData;
  final Function(String actionType, String? offerId)? onAction;

  const ItinerarySummary({
    Key? key,
    required this.widgetData,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widgetData.title ?? 'Résumé de l\'itinéraire',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Contenu depuis data
              if (widgetData.data != null) ...[
                _buildItineraryContent(widgetData.data!),
              ],

              // Actions
              if (widgetData.actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widgetData.actions.map((action) {
                    return ElevatedButton(
                      onPressed: () {
                        onAction?.call(action.type, widgetData.offerId);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(action.label),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItineraryContent(Map<String, dynamic> data) {
    final List<Widget> items = [];

    if (data['flight'] != null) {
      items.add(_buildItineraryItem(
        Icons.flight_takeoff,
        'Vol',
        data['flight'] as String,
      ));
    }

    if (data['hotel'] != null) {
      items.add(_buildItineraryItem(
        Icons.hotel,
        'Hôtel',
        data['hotel'] as String,
      ));
    }

    if (data['total_price'] != null) {
      items.add(_buildItineraryItem(
        Icons.euro,
        'Prix total',
        data['total_price'] as String,
        isHighlight: true,
      ));
    }

    return Column(
      children: items,
    );
  }

  Widget _buildItineraryItem(
    IconData icon,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? Colors.blue[900] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Critères d'acceptation** :
- ✅ Design distinctif (fond coloré)
- ✅ Affichage du résumé (vol + hôtel + prix total)
- ✅ Actions disponibles (ex: "Finaliser la réservation")
- ✅ Mise en évidence du prix total

**Estimation** : 1h30

---

### Tâche 7.5 : Créer WarningWidget
**Fichier** : `bagtrip/lib/chat/widgets/warning_widget.dart`

**Spécifications** :

Widget pour afficher des avertissements (visa, budget, etc.).

```dart
import 'package:flutter/material.dart';
import 'package:bagtrip/chat/models/context.dart';

class WarningWidget extends StatelessWidget {
  final WidgetData widgetData;
  final Function(String actionType, String? offerId)? onAction;

  const WarningWidget({
    Key? key,
    required this.widgetData,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange[300]!, width: 1),
        ),
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec icône warning
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[800],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widgetData.title ?? 'Avertissement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Message
              if (widgetData.subtitle != null)
                Text(
                  widgetData.subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[800],
                  ),
                ),

              // Informations supplémentaires
              if (widgetData.data != null && widgetData.data!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildWarningDetails(widgetData.data!),
              ],

              // Actions
              if (widgetData.actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widgetData.actions.map((action) {
                    return OutlinedButton(
                      onPressed: () {
                        onAction?.call(action.type, widgetData.offerId);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        side: BorderSide(color: Colors.orange[800]!),
                        foregroundColor: Colors.orange[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(action.label),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningDetails(Map<String, dynamic> data) {
    final List<Widget> items = [];

    if (data['type'] != null) {
      items.add(_buildDetailRow('Type', data['type'] as String));
    }

    if (data['message'] != null) {
      items.add(_buildDetailRow('Message', data['message'] as String));
    }

    if (data['action_required'] != null) {
      items.add(_buildDetailRow(
        'Action requise',
        data['action_required'] as String,
        isImportant: true,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[800],
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Critères d'acceptation** :
- ✅ Design distinctif (couleur orange/warning)
- ✅ Affichage clair du message d'avertissement
- ✅ Support des détails supplémentaires
- ✅ Actions disponibles si nécessaire

**Estimation** : 1h

---

### Tâche 7.6 : Intégrer WidgetRenderer dans ChatPage
**Fichier** : `bagtrip/lib/pages/chat_page.dart`

**Modifications** :

Remplacer la méthode `_buildWidgetCard` actuelle par l'utilisation du `WidgetRenderer`.

**Avant** :
```dart
Widget _buildWidgetCard(WidgetData widgetData, ChatLoaded state) {
  return Container(
    // ... implémentation basique actuelle
  );
}
```

**Après** :
```dart
import 'package:bagtrip/chat/widgets/widget_renderer.dart';

// Dans le build, remplacer :
itemBuilder: (context, index) {
  final widgetData = state.context!.ui.widgets[index];
  return WidgetRenderer(
    widgetData: widgetData,
    onAction: (actionType, offerId) {
      _handleWidgetAction(actionType, offerId, state);
    },
  );
}

// Nouvelle méthode pour gérer les actions
void _handleWidgetAction(
  String actionType,
  String? offerId,
  ChatLoaded state,
) {
  if (offerId == null) return;

  final offerType = actionType.contains('FLIGHT') ? 'FLIGHT' : 'HOTEL';

  if (actionType == 'SELECT_FLIGHT' || actionType == 'SELECT_HOTEL') {
    context.read<ChatBloc>().add(
          SelectOffer(
            tripId: widget.tripId,
            conversationId: widget.conversationId,
            offerId: offerId,
            offerType: offerType,
            contextVersion: state.context?.version,
          ),
        );
  } else if (actionType == 'BOOK_FLIGHT' || actionType == 'BOOK_HOTEL') {
    context.read<ChatBloc>().add(
          BookOffer(
            tripId: widget.tripId,
            conversationId: widget.conversationId,
            offerId: offerId,
            offerType: offerType,
            contextVersion: state.context?.version,
          ),
        );
  }
}
```

**Critères d'acceptation** :
- ✅ `_buildWidgetCard` remplacé par `WidgetRenderer`
- ✅ Gestion des actions centralisée dans `_handleWidgetAction`
- ✅ Intégration avec ChatBloc fonctionnelle
- ✅ Pas de régression dans l'affichage

**Estimation** : 1h

---

### Tâche 7.7 : Tests et validation
**Fichiers** : Tests manuels + vérifications

**Tests à effectuer** :

1. **Rendu des widgets** :
   - ✅ FlightOfferCard s'affiche correctement avec toutes les données
   - ✅ HotelOfferCard s'affiche correctement avec toutes les données
   - ✅ ItinerarySummary s'affiche correctement
   - ✅ WarningWidget s'affiche correctement
   - ✅ Widget inconnu affiche le fallback

2. **Actions** :
   - ✅ Clic sur "Choisir" déclenche SelectOffer
   - ✅ Clic sur "Réserver" déclenche BookOffer
   - ✅ Actions fonctionnent pour vols et hôtels
   - ✅ Version du contexte envoyée correctement

3. **Intégration** :
   - ✅ Widgets s'affichent dans la zone horizontale
   - ✅ Scroll horizontal fonctionne
   - ✅ Design cohérent avec le reste de l'app
   - ✅ Performance acceptable (pas de lag)

4. **Edge cases** :
   - ✅ Widget sans title/subtitle
   - ✅ Widget sans actions
   - ✅ Widget avec data vide
   - ✅ Widget avec offerId null

**Critères d'acceptation** :
- ✅ Tous les tests passent
- ✅ Aucune régression détectée
- ✅ Design cohérent et moderne
- ✅ Performance acceptable

**Estimation** : 2h

---

## 📁 Structure des fichiers à créer/modifier

### Nouveaux fichiers

```
bagtrip/lib/chat/widgets/
  ├── widget_renderer.dart        [NOUVEAU]
  ├── flight_offer_card.dart        [NOUVEAU]
  ├── hotel_offer_card.dart         [NOUVEAU]
  ├── itinerary_summary.dart        [NOUVEAU]
  └── warning_widget.dart          [NOUVEAU]
```

### Fichiers à modifier

```
bagtrip/lib/pages/
  └── chat_page.dart                [MODIFIER - remplacer _buildWidgetCard]
```

---

## 🎨 Design Guidelines

### Principes de design

1. **Cohérence** : Tous les widgets doivent suivre le même style Material Design
2. **Lisibilité** : Informations importantes mises en évidence
3. **Interactivité** : Actions claires et accessibles
4. **Responsive** : Widgets adaptés à différentes tailles d'écran
5. **Accessibilité** : Support des contrastes et tailles de texte

### Palette de couleurs

- **FlightOfferCard** : Bleu (`Colors.blue`)
- **HotelOfferCard** : Orange (`Colors.orange`)
- **ItinerarySummary** : Bleu clair (`Colors.blue[50]`)
- **WarningWidget** : Orange/Warning (`Colors.orange`)

### Tailles standard

- **Largeur widget** : 320px (fixe pour scroll horizontal)
- **Padding** : 16px
- **Border radius** : 12px
- **Elevation** : 2-3 selon importance

---

## 🔄 Flux de données

### Affichage des widgets

```
1. Backend envoie context.updated via SSE
   → context.ui.widgets = [WidgetData, ...]
2. ChatBloc reçoit ContextUpdatedEvent
   → Met à jour state.context
3. ChatPage rebuild
   → ListView.builder itère sur state.context.ui.widgets
4. WidgetRenderer rend le bon widget selon widgetData.type
5. Widget affiche les données (title, subtitle, data, actions)
```

### Gestion des actions

```
1. User clique sur un bouton d'action dans un widget
   → WidgetRenderer.onAction(actionType, offerId)
2. ChatPage._handleWidgetAction()
   → Détermine le type d'action (SELECT/BOOK)
   → Détermine le type d'offre (FLIGHT/HOTEL)
3. ChatBloc reçoit SelectOffer ou BookOffer event
   → Appelle AgentService.action()
   → Envoie requête à POST /v1/agent/actions
4. Backend traite l'action
   → Met à jour le contexte
   → Retourne réponse SSE
5. ChatBloc reçoit la réponse
   → Met à jour le state
   → UI se met à jour
```

---

## ✅ Checklist de validation

### Widget Renderer
- [x] Factory pattern implémenté
- [x] Support de tous les types de widgets
- [x] Fallback pour types inconnus
- [x] Callback onAction fonctionnel

### Widgets individuels
- [x] FlightOfferCard créé et fonctionnel
- [x] HotelOfferCard créé et fonctionnel
- [x] ItinerarySummary créé et fonctionnel
- [x] WarningWidget créé et fonctionnel
- [x] Design cohérent entre tous les widgets
- [x] Actions cliquables et fonctionnelles

### Intégration
- [x] WidgetRenderer intégré dans ChatPage
- [x] _buildWidgetCard remplacé
- [x] Gestion des actions centralisée
- [x] Intégration avec ChatBloc fonctionnelle

### Tests
- [x] Rendu de tous les types de widgets testé
- [x] Actions testées (SELECT/BOOK)
- [x] Edge cases gérés
- [x] Performance acceptable
- [x] Aucune régression

---

## 🚀 Ordre d'exécution recommandé

1. ✅ **Tâche 7.1** : Créer WidgetRenderer (fondation) - **COMPLÉTÉ**
2. ✅ **Tâche 7.2** : Créer FlightOfferCard (premier widget) - **COMPLÉTÉ**
3. ✅ **Tâche 7.3** : Créer HotelOfferCard (deuxième widget) - **COMPLÉTÉ**
4. ✅ **Tâche 7.4** : Créer ItinerarySummary (troisième widget) - **COMPLÉTÉ**
5. ✅ **Tâche 7.5** : Créer WarningWidget (quatrième widget) - **COMPLÉTÉ**
6. ✅ **Tâche 7.6** : Intégrer dans ChatPage - **COMPLÉTÉ**
7. ✅ **Tâche 7.7** : Tests et validation - **COMPLÉTÉ**

---

## 📝 Notes importantes

### Extensibilité

Le système est conçu pour être facilement extensible :

1. **Nouveau type de widget** :
   - Créer le widget dans `bagtrip/lib/chat/widgets/`
   - Ajouter le case dans `WidgetRenderer`
   - Backend doit envoyer le type dans `context.ui.widgets[].type`

2. **Nouvelle action** :
   - Ajouter le type d'action dans `WidgetAction.type`
   - Gérer le cas dans `ChatPage._handleWidgetAction()`
   - Backend doit gérer l'action dans `POST /v1/agent/actions`

### Performance

- Les widgets sont stateless pour optimiser les rebuilds
- Utilisation de `const` constructors quand possible
- ListView.builder pour le scroll horizontal (lazy loading)

### Backend contract

Le backend doit envoyer les widgets dans ce format :

```json
{
  "context": {
    "ui": {
      "widgets": [
        {
          "type": "FLIGHT_OFFER_CARD",
          "offer_id": "uuid",
          "title": "Paris → Rome",
          "subtitle": "À partir de 189€",
          "data": {
            "departure": "CDG",
            "arrival": "FCO",
            "duration": "2h 30min",
            "stops": 0
          },
          "actions": [
            {
              "type": "SELECT_FLIGHT",
              "label": "Choisir"
            },
            {
              "type": "BOOK_FLIGHT",
              "label": "Réserver"
            }
          ]
        }
      ]
    }
  }
}
```

---

## 🔗 Liens avec les épics suivants

- **Epic 8** : Les widgets seront testés dans le flow complet
- **Epic 3** : Le backend doit envoyer les widgets correctement formatés

---

## 📚 Références

- Modèles de contexte : `bagtrip/lib/chat/models/context.dart`
- ChatPage actuel : `bagtrip/lib/pages/chat_page.dart`
- ChatBloc : `bagtrip/lib/chat/bloc/chat_bloc.dart`
- Material Design Guidelines : https://material.io/design

---

**Date de création** : 2026-01-08
**Dernière mise à jour** : 2026-01-08
**Statut** : ✅ Complété
