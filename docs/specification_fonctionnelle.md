Vue d'ensemble

Bag Trip est une application mobile multiplateforme qui permet aux voyageurs de planifier et organiser leurs séjours. Elle intègre des outils de planification d’itinéraires, d’agenda, de budget, ainsi qu’un chatbot d’assistance. Une plateforme web est également proposée aux administrateurs.

Services principaux

Planification de voyages avec itinéraires personnalisés

Informations sur événements et lieux à destination

Gestion de budget

Visualisation cartographique des itinéraires

Services secondaires

Chatbot d’assistance 24/7

Accès hors ligne à certaines fonctionnalités

1. Introduction

Sujet du document

Ce document détaille le fonctionnement, la conception et les exigences techniques de l’application Bag Trip.

Appareils ciblés

Type : Smartphone

Plateformes :

Android ≥ 13 (Tiramisu)

iOS ≥ 16

2. Fonctionnalités principales (Mobile)

2.1 Planificateur de voyages

Création d’itinéraires

Choix du mode de transport : vol, train, bus

Types de trajets : aller simple, aller-retour, multidestination

Champs de recherche pour départ/destination avec suggestions

Sélection de dates, nombre de passagers, animaux

Option vol + hôtel

Création d’itinéraires personnalisés

Structuration par jour ou par étape

Ajout de lieux (manuellement ou suggestions)

Réorganisation des étapes par glisser-déposer

Suggestions de lieux

Lieux filtrables par catégorie : restaurants, hôtels, attractions, etc.

Affichage en liste ou carte (via Mapbox)

Tri par distance, avis, type de voyageurs

Sauvegarde & modification

Sauvegarde automatique et manuelle

Accès local et cloud

Modification d’itinéraire existant

Suppression

Confirmation obligatoire

Option d’annulation temporaire après suppression

Affichage cartographique

Carte interactive avec marqueurs

Zoom automatique, navigation manuelle

Mode hors ligne avec préchargement

2.2 Agenda

Ajout & modification d’événements

Formulaire avec titre, date, heure, lieu, catégorie

Association à un jour d’itinéraire

Notifications : heure, jour, semaine, mois avant

Suppression

Confirmation de suppression

Suppression synchronisée avec Google Calendar

Affichage

Vue liste triée par date/heure

Vue calendrier : jour/semaine/mois

Recherche et filtres : date, catégorie, mot-clé

Synchronisation Google Calendar

Authentification

Ajout/modification/suppression synchronisés

Option d’activation

2.3 Gestion de budget

Conversion de devises

Taux mis à jour toutes les heures ou manuellement

Stockage local des taux pour usage hors ligne

Budget prévisionnel

Définition/modification du montant et devise

Suivi des dépenses

Formulaire avec titre, catégorie, montant, devise, date

Modification et suppression avec confirmation

Tri par date, catégorie ; recherche par mot-clé

Graphiques et rapports

Pourcentage du budget consommé

Graphiques : camembert, barre de progression

Sauvegarde des données du voyage

3. Fonctionnalités secondaires (Mobile)

3.1 Mode hors ligne

Consultation des itinéraires, cartes, dépenses, traductions

Ajout/modification d’événements (synchronisation différée)

Préchargement

Cartes, itinéraires, hôtels

Mises à jour automatiques après reconnexion

Cache des traductions

Stockage local des traductions précédentes

Historique filtrable par date, langue, voyage

Suppression automatique après 1 mois

3.2 Chatbot d’assistance

Modèle NLP

Réponses contextuelles

Conversation avec continuité, possibilité d’arrêter/réinitialiser

Prompt personnalisé

Réponses adaptées au contexte de voyage

Requêtes guidées par boutons cliquables

Gestion des erreurs

Messages alternatifs si pas de réponse possible

FAQ et support rapide

Base de questions fréquentes disponible en mode hors ligne

4. Fonctionnalités (Back-office site web)

4.1 Gestion des utilisateurs

Ajout, modification, suppression

Champs requis : prénom, nom, email, mot de passe, rôle, statut

Réinitialisation du mot de passe par email

Soft delete possible

Filtres

Recherche par nom, email, rôle, statut

4.2 Suivi des activités

Journal des connexions, actions utilisateurs

Export CSV des logs

Tableau de bord par utilisateur

4.3 Droits et permissions

Rôles personnalisés avec permissions associées

Affectation lors de la création ou modification

Affichage conditionnel dans le back-office

4.4 KPI

Nombre total d’utilisateurs inscrits

Nombre d’utilisateurs actifs (connectés dans les dernières 24h / 7 jours)

Graphique d’évolution hebdomadaire :

nouveaux utilisateurs

utilisateurs actifs


Tri par popularité (nombre d’utilisateurs ayant sélectionné cette destination)

Filtre “Voyages en cours” : affiche uniquement les destinations où des utilisateurs sont actuellement en voyage

Filtre par période passée (dates précises ou saison : été, hiver, etc.)

Accès aux détails d’une destination :

durée moyenne des voyages

graphique montrant le nombre de voyageurs par destination sur les 6 derniers mois


Liste complète des messages envoyés par les utilisateurs (avis, suggestions, retours)

Possibilité de trier par date, type, ou niveau de gravité (si précisé)

4.5 Gestions des indispensables

Affichage de toutes les destinations associées à une checklist

Barre de recherche pour trouver rapidement une destination

Filtres par : région, popularité, date d’ajout, etc.

Ajouter un élément indispensable

Modifier un élément existant

Supprimer un élément

Réordonner (BONUS)
