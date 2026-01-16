

1. Introduction

1.1 Objet du document

Ce document décrit les spécifications techniques nécessaires au développement de l’application Bag Trip. Il complète les spécifications fonctionnelles en précisant les tâches à réaliser, les technologies à utiliser et les tickets à planifier.

1.2 Périmètre

Application mobile multi-plateforme (Android ≥ 13, iOS ≥ 16)

Plateforme web d’administration (gestion, statistiques, feedbacks)

1.3 Public visé

Équipe de développement : mobile, back-end, front-end, QA

Chef de projet et équipe produit

2. Architecture générale

2.1 Front-end Mobile

Technologie : Flutter

2.2 Back-end

Technologie : Node.js (API REST), PostgreSQL

Authentification : JWT / OAuth

Fonctionnalités : gestion utilisateurs, données voyage, intégration API externes

2.3 Services externes

Amadeus API (données voyages)

Lien documentation : developers.amadeus.com

VOL

Flight Offers Search

Endpoint (required)

Description

Exemple

originLocationCode

type: String

Code IATA correspondant au lieu de départ du voyageur.

Le code IATA doit être récupérer depuis l’endpoint city/airport.

PAR → Paris

BOS → Boston

SYD → Sydney

destinationLocationCode

type: String

Code IATA correspondant au lieu d’arrivé du voyageur.

Le code IATA doit être récupérer depuis l’endpoint city/airport.

PAR → Paris

BOS → Boston

SYD → Sydney

departureDate

type: String(Date)

Date où le voyageur veut partir depuis le lieu de départ.

ISO 8601

Format → YYYY-MM-DD

2025-12-25

adults

type: Int

Nombre de personne adultes qui voyagent.

12 ans ou plus à la date de départ.

Valeur par défaut : 1

Ne peut pas excéder 9 personnes.

1







Endpoint (optional)

Description

Exemple

returnDate

type: String(Date)

Date où le voyageur veut partir depuis le lieu de destination pour revenir à son lieu de départ.

ISO 8601

Format → YYYY-MM-DD

2026-01-01

children

type: Int

Nombre de personne enfants qui voyagent.

+2ans et -12 ans à la date de départ.

Valeur par défaut : 1

Ne peut pas excéder 9 personnes.

1

infants

type: Int

Nombre de nourrissons qui voyagent.

Les nourrissons voyagent sur les genoux d'un voyageur adulte, et donc le nombre de nourrissons ne doit pas dépasser le nombre d'adultes

-2ans à la date de départ.

Valeur par défaut : 1

Ne peut pas excéder 9 personnes.

1

travelClass

type: String

Choix de la qualité de la cabine.

Valeur disponibles :

ECONOMY

PREMIUM_ECONOMY

BUSINESS

FIRST

Valeur par défaut : Prend en compte toutes les classes disponibles.

ECONOMY

nonStop

type: Bool

Si true, la recherche ne trouvera que des vols allant du départ à la destination sans correspondance entre les deux.

Valeur par défaut: false

false

currencyCode

type: String

La devise préférée pour les offres de vol.

ISO 4217

Format: EUR

EUR → Euro

USD → United States Dollar

maxPrice

type: Int

Le montant maximum par voyageur.

La valeur doit être positive et un nombre entier. Les décimaux ne sont pas autorisés.

1200

max

type: Int

Nombre maximum d’offres de vols retournés.

Valeur par défaut: 250

⚠️ À définir.
250 est un nombre trop grand nécessitant une pagination. Aussi, il y a une question de performance.

10







Endpoint (unused)

Description

Exemple

includedAirlineCodes

type: String





excludedAirlineCodes

type: String







Flight Offers Search Result

Data

type: Array

Description

Exemple

type

type: String

Type de ressources.

flight-offer

id

type: String

Identifiant unique de l’offre.

1

source

type: String

Sources des données.

GDS

Global Distribution System

instantTicketingRequired

type: Bool

Si true, le billet est à remettre immédiatement.

false | true

nonHomogeneous

type: Bool





oneWay

type: Bool

true = aller simple

fasle = aller-retour

false | true

isUpsellOffer

type: Bool

Offre de surclassement ou promotion spéciale.

false | true

lastTicketingDate

type: Date

Dernière date possible d’émission du billet.

Format → YYYY-MM-DD

2025-12-27

lastTicketingDateTime





numberOfBookableSeats

type: Int

Nombre de sièges disponibles à la vente pour cette offre.

4







Data.Itineraries

itineraries

type: Array

Liste des trajets.



duration

type: String

Durée totale du trajet.

PT2H (= 2 heures)







Data.Itineraries.Segments

segments

type: Array

Détails de chaque vol (escales, correspondances, terminal,…)



carrierCode

type: String

Code compagnie opératrice du vol.

IB

number

type: Int

Numéro du vol.

5418

duration

type: String

Durée du segment individuel du trajet.

PT2H (= 2 heures)

id

type: String





numberOfStops

type: String

Nombre d’escales sur le segment individuel du trajet.

0

blacklistedInEU

type: Bool

Indique si la compagnie est sur liste noire UE.

false | true

Data.Itineraries.Segments.Departure

departure

type: Array

Informations de départ du vol.



iataCode

type: String

Code aéroport de départ.

ORY → Orly

terminal

type: String

Terminal de départ.

1

at

type: DateTime

Heure de départ locale.

2025-11-13T09:50:00

Data.Itineraries.Segments.Arrival

arrival

type: Array

Informations d’arrivée du vol.



iataCode

type: String

Code aéroport d’arrivée.

FCO → Rome

terminal

type: String

Terminal de d’arrivée.

1

at

type: DateTime

Heure d’arrivée locale.

2025-11-13T11:50:00

Data.Itineraries.Segments.Aircraft

aircraft

type: Array





code

type: String

Code du type d’appareil.

320

Data.Itineraries.Segments.Operating

operating

type: Array





carrierCode







Benchmark

Aspect

Plan Gratuit (Self-Service)

Plan Payant (Production/Enterprise)

Tarification

Compte gratuit avec accès sandbox

Paiement à l’appel ou contrat entreprise

Coût indicatif

0 $ (avec quotas mensuels)

Variable (ex. quelques centimes / appel)

Limites

200 à 10 000 appels/mois selon l’API

Appels illimités (au-delà du quota gratuit)

Débit (QPS)

~10 requêtes/sec

Supérieur si contractualisé

Dev possible ?

Oui, parfait pour le prototypage

Requis en production avec trafic rée

Endpoint

Plan Gratuit

requêtes par mois

Plan Payant

€ par requête

Flight Offers Search

Recherche des offres de vols par IATA

ex: Charles de Gaulle → CDG

v2/shopping/flight-offers



2 000



0.025

Flight Offers Price

Le prix et la disponibilité des billets d'avion fluctuent constamment, il est donc nécessaire de confirmer le prix en temps réel avant de procéder à la réservation. L'API de prix des offres de vol confirme la disponibilité et le prix final (y compris les taxes et les frais) des vols retournés par l'API de recherche d'offres de vols.

v1/shopping/flight-offers/pricing







3 000







0.0015

Flight Create Orders

Créer une ordre de réservation.

v1/booking/flight-orders



10 000



0.04

Flight Order Management

Gérer les modification et annulations de la réservation.

/v1/booking/flight-orders/{{flightOrderId}}



5 000



0.0025

Airport & City Search

Recherche de destination par nom de ville.

v1/reference-data/locations

v1/reference-data/locations/*





7 000

3 000





0.0025

0.0025







ExchangeRateAPI (conversion de devises)

Lien documentation : exchangeratesapi.io/documentation

Benchmark

Aspect

Plan Gratuit

Plan Payant (Pro/Business)

Tarification

100 % gratuit

Abonnements mensuels

Coût indicatif

0 $ (1 500 requêtes/mois)

Pro : ~10 $/mois / Business : ~30 $/mois

Limites

1 appel/jour max par taux / 1 500 appels

30k à 125k appels/mois / rafraîchissement fréquent

Débit (QPS)

Non garanti

Rafraîchissement toutes les 5 min

Dev possible ?

Oui, suffisant pour petits projets

Requis pour production ou usage fréquent

Google Calendar API (synchronisation agenda)

Lien documentation : developers.google.com/workspace/calendar

Benchmark

Aspect

Plan Gratuit

Plan Payant

Tarification

Gratuit (API publique)

Aucun plan payant

Coût indicatif

0 $

N/A

Limites

~1 000 000 requêtes/jour par projet

N/A

Débit (QPS)

~100 req/min/utilisateur

N/A

Dev possible ?

Oui, totalement

N/A – API toujours gratuite

Endpoint (REST)

Fonction principale

Quota gratuit (par jour)

Prix après quota gratuit

/calendar/v3/calendars

Création/gestion de calendriers

1 000 000 requêtes/jour

Gratuit (dans la limite)

/calendar/v3/calendars/events

Ajouter/lister/modifier/supprimer des événements

1 000 000 requêtes/jour

Gratuit (dans la limite)

/calendar/v3/freeBusy

Vérifier les disponibilités

1 000 000 requêtes/jour

Gratuit (dans la limite)

Gemini (chatbot IA)

Benchmark

Voici le tableau Gemini 1.5 Flash inversé, avec les aspects en ligne et les formules en colonne, comme pour les autres services. Ce format est prêt à être intégré dans Notion :

Gemini 1.5 Flash

Aspect

Formule gratuite (Google AI Studio)

Formule payante (Vertex AI)

Tarification

Gratuit via Google AI Studio

Paiement à l’usage via Vertex AI

Coût indicatif

Entrée : gratuitSortie : gratuit

Entrée : 0,30 $/1M tokensSortie : 2,50 $/1M tokens

Limites

500 requêtes/jour10 requêtes/minute

10 000 requêtes/jour1 000 requêtes/minute

Débit (QPS)

~10 requêtes/minute

~1 000 requêtes/minute

Dev possible ?

Oui, parfait pour développement et tests

Oui, pour mise en production à grande échelle

Google places (cartographie)

Lien documentation : docs.google-places.com

Benchmark



Aspect

Plan Gratuit

Plan Payant

Tarification

Crédit gratuit mensuel (~10k requêtes)

Pay-as-you-go par requête

Coût indicatif

0 $ (jusqu’à épuisement du crédit)

À partir de ~0,017 $/requête

Limites

10 000 à 30 000 requêtes/mois selon le type d’API

Illimité (facturation après quota)

Débit (QPS)

50 requêtes/sec par projet (modulable)

Quotas ajustables via GCP

Dev possible ?

Oui, largement suffisant pour tests

Requis en production intensive

Base URL:

Endpoint (REST)

Fonction / Utilité

Quota gratuit (par mois)

Prix après quota gratuit

Lien

https://places.googleapis.com/v1/places:autocomplete

Saisie semi-automatique de lieux (pour recherche d’adresse)

10 000

2,83 $ / 1 000 requêtes

https://developers.google.com/maps/documentation/places/web-service/place-autocomplete?hl=fr

/maps/api/geocode/json

Géocodage (adresse → coordonnées, et inversement)

10 000

5 $ / 1 000 requêtes



/maps/api/geolocation/v1/geolocate

Géolocalisation de l'utilisateur (IP/Wifi/GSM)

10 000

5 $ / 1 000 requêtes



https://places.googleapis.com/v1/places/PLACE_ID

Infos détaillées sur un lieu (par place_id)

10 000

5 $ / 1 000 requêtes

https://developers.google.com/maps/documentation/places/web-service/place-details?hl=fr

https://places.googleapis.com/v1/places:searchText

Recherche de lieux par texte (nom, adresse…)

Illimité

Inclus avec Place Details

https://developers.google.com/maps/documentation/places/web-service/text-search?hl=fr

https://places.googleapis.com/v1/places:searchNearby

Recherche à proximité (restaurant…)

Illimité

Inclus avec Place Details

https://developers.google.com/maps/documentation/places/web-service/nearby-search?hl=fr

/maps/api/timezone/
json

Fuseau horaire pour un lieu donné

10 000

5 $ / 1 000 requêtes



https://places.googleapis.com/v1/NAME/media?key=API_KEY&PARAMETERS

Récupérer une photo de lieu (Place Photo API)

Inclus (dépend du quota)

Variable, selon la taille image

https://developers.google.com/maps/documentation/places/web-service/place-photos?hl=fr





Mapbox (cartographie)

Lien documentation : docs.mapbox.com

Benchmark

Aspect

Plan Gratuit

Plan Payant

Tarification

Freemium mensuel

Paiement à l’usage (unités)

Coût indicatif

0 $ jusqu’à 50k vues cartes / 100k requêtes API

5 $/1 000 vues – 0,75 $/1 000 requêtes géo

Limites

50k vues carte / 100k géocodages/mois

Illimité, facturé au-delà

Débit (QPS)

Suffisant pour dev

Évolutif selon volume

Dev possible ?

Oui, très adapté

Requis si trafic élevé en prod

Endpoint

Plan Gratuit

Plan Payant

Tarification

Freemium mensuel

Paiement à l’usage (unités)

Limites

10k sauf

utilisation des sessions de saisie semi-automatique

API Places : éléments essentiels de Place Details (ID uniquement)

Principes de base de Text Search dans l'API Places (ID uniquement)

Illimité, facturé au-delà

3. Technologies & Dépendances

Front-end : Flutter, OAuth, Google SDK, Mapbox SDK

Back-end : Node.js, Express, PostgreSQL, Sequelize

CI/CD : GitHub Actions, Play Console, TestFlight

Tests : Jest, Cypress, Appium

Authentification : JWT / OAuth, rôles et permissions

4. Qualité, Tests & Livraisons

Tests unitaires sur modules (checklist, agenda, chatbot...)

Tests d'intégration entre front, back et APIs

Tests E2E : de la création d’un voyage à la synchro calendrier

CI/CD : automatisation des tests, build, déploiement

Distribution : Google Play Console, TestFlight

Environnement staging avant production

5. Sécurité

Authentification JWT / OAuth

Sécurisation API via middlewares

HTTPS (TLS)

Chiffrement local des données sensibles

Tests de vulnérabilité (XSS, injections, etc.)

6. Backlog Technique

6.1 Planificateur de voyage

Ticket ID

User Story

Tâches

Critères d’acceptation

SP

PV-01

Page d’accueil avec 3 options de départ

UI + navigation

Navigation fluide

3

PV-02

Questionnaire pour planifier un voyage

Stockage des réponses

Destination adaptée

5

PV-03

Affichage des hôtels filtrables

Google Places + filtres

Filtres actifs fonctionnels

5

PV-04

Suggestions autour de l'hébergement

API + affichage

Activités localisées

3

6.2 Plateforme Web Admin

Ticket ID

User Story

Tâches

Critères d’acceptation

SP

ADM-01

Connexion admin sécurisée

Login + vérification

Accès restreint

3

ADM-02

Gestion des utilisateurs

CRUD avec filtres

Liste fonctionnelle

5

ADM-03

Visualisation des feedbacks

Table + actions

MAJ réactive

3

ADM-04

Statistiques d’usage

Dashboard avec KPIs

Données en temps réel

3

6.3 Backend & API

Ticket ID

User Story

Tâches

Critères d’acceptation

SP

API-01

API REST avec DB

Express + PostgreSQL

Requêtes REST OK

5

API-02

Intégration API externes

Sécurisation + erreurs

Réponse < 2s

5

API-03

Modèle relationnel clair

Tables + indexation

Cohérence métier

3

6.4 Tests & Livraison

Ticket ID

User Story

Tâches

Critères d’acceptation

SP

TEST-01

Tests unitaires

Implémentation

Couverture > 80%

5

TEST-02

Tests fonctionnels

Retours utilisateurs

Aucun blocage

5

LIV-01

Livraison version alpha

Déploiement stores

Disponibilité

3

6.5 Fonctionnalités principales

Ticket ID

User Story

Tâches

Critères d’acceptation

SP

FE-01

Résumé de voyage + checklist

UI récapitulatif

Données en temps réel

3

FE-02

Ajout et visualisation des dépenses

Formulaire + graphes

Conversion correcte

5

FE-03

Checklist dynamique

Ajout catégories

UI claire, sauvegarde

3

FE-04

Chatbot

Prompt + réponses

Chat utile

3

FE-05

Synchronisation calendrier

OAuth + événements

Données synchronisées

5

7. Conclusion

Ce document constitue une base structurée de travail pour l’ensemble de l’équipe projet, du développement à la mise en production. Il permet de piloter efficacement l’avancement grâce à des tickets clairs, estimés, et actionnables, intégrant technologies, livrables et contraintes techniques.
