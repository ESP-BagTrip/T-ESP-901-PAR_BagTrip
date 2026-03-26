# Hebergements

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

La feature Hebergements permet aux utilisateurs de gerer leurs logements pour chaque voyage. Elle combine trois modes d'ajout : saisie manuelle, recherche d'hotels via Amadeus et suggestions IA. Chaque hebergement est lie a un trip et stocke nom, adresse, dates check-in/check-out, prix par nuit, devise, reference de reservation et notes.

---

## Architecture mobile (Flutter)

### BLoC

`AccommodationBloc` (`bagtrip/lib/accommodations/bloc/accommodation_bloc.dart`) gere l'ensemble de la feature via `AccommodationRepository`.

| Event | Action |
|-------|--------|
| `LoadAccommodations` | Charge tous les hebergements du trip |
| `CreateAccommodation` | Cree un hebergement (ajout optimiste dans la liste courante) |
| `UpdateAccommodation` | Met a jour un hebergement existant (remplacement dans la liste) |
| `DeleteAccommodation` | Supprime un hebergement (retrait de la liste) |
| `SuggestAccommodations` | Appelle l'IA pour des suggestions d'hebergement |
| `SearchHotels` | Recherche d'hotels par ville via Amadeus (cityCode, checkIn, checkOut, adults) |
| `SearchHotelOffers` | Recherche d'offres avec prix pour une liste d'hotel IDs |
| `ClearHotelSearch` | Reset le state vers `AccommodationInitial` |

### Etats

| State | Description |
|-------|-------------|
| `AccommodationInitial` | Etat initial |
| `AccommodationLoading` | Chargement de la liste |
| `AccommodationsLoaded` | Liste d'`Accommodation` disponible |
| `AccommodationError` | Erreur avec `AppError` |
| `AccommodationSuggestionsLoading` | Chargement des suggestions IA |
| `AccommodationSuggestionsLoaded` | Suggestions recues (`List<Map<String, dynamic>>`) |
| `AccommodationQuotaExceeded` | Quota IA depasse |
| `HotelSearchLoading` | Recherche hotel en cours |
| `HotelSearchLoaded` | Resultats de recherche hotel (`List<Map<String, dynamic>>`) |

### Modele Freezed

`Accommodation` (`bagtrip/lib/models/accommodation.dart`) :
- `id`, `tripId`, `name` (obligatoires)
- `address`, `checkIn`, `checkOut`, `pricePerNight`, `currency`, `bookingReference`, `notes` (optionnels)
- `createdAt`, `updatedAt`

### Widgets

| Widget | Fichier | Role |
|--------|---------|------|
| `AccommodationsPage` | `accommodations/view/accommodations_page.dart` | Cree le `BlocProvider` et fire `LoadAccommodations` |
| `AccommodationsView` | `accommodations/view/accommodations_view.dart` | UI principale avec liste et actions |
| `AccommodationCard` | `accommodations/widgets/accommodation_card.dart` | Carte individuelle d'un hebergement |
| `AddAccommodationSheet` | `accommodations/widgets/add_accommodation_sheet.dart` | Bottom sheet avec choix du mode d'ajout |
| `ManualAccommodationForm` | `accommodations/widgets/manual_accommodation_form.dart` | Formulaire de saisie manuelle |
| `HotelSearchSheet` | `accommodations/widgets/hotel_search_sheet.dart` | Interface de recherche hotel Amadeus |
| `AiSuggestionsSheet` | `accommodations/widgets/ai_suggestions_sheet.dart` | Affichage des suggestions IA |

### Trois modes d'ajout

1. **Manuel** : Le formulaire `ManualAccommodationForm` permet de saisir directement nom, adresse, dates, prix/nuit, devise, reference de reservation et notes.

2. **Recherche hotel Amadeus** : Le `HotelSearchSheet` permet de chercher par code ville IATA (ex: PAR). Flux en deux etapes :
   - `SearchHotels` : recupere la liste d'hotels par ville (nom, hotelId, adresse, geo)
   - `SearchHotelOffers` : pour un hotel selectionne, recupere les offres avec prix (checkIn, checkOut, room, price)

3. **Suggestions IA** : L'event `SuggestAccommodations` appelle le backend pour obtenir des suggestions contextualisees. Gere le quota IA avec l'etat `AccommodationQuotaExceeded`.

---

## Architecture backend (FastAPI)

### Endpoints hebergements

#### CRUD Accommodations

- `POST /v1/trips/{tripId}/accommodations` — Cree un hebergement. Body : `name` (obligatoire), `address?`, `checkIn?`, `checkOut?`, `pricePerNight?` (Decimal), `currency?`, `bookingReference?`, `notes?`. Owner only. Retourne 201.

- `GET /v1/trips/{tripId}/accommodations` — Liste les hebergements du trip. Owner + Viewer. **Masquage pour viewers** : `pricePerNight`, `currency` et `bookingReference` sont mis a null pour le role VIEWER.

- `PATCH /v1/trips/{tripId}/accommodations/{accommodationId}` — Mise a jour partielle. Owner only. Supporte le clearing explicite du prix (si `pricePerNight` est dans `model_fields_set` mais vaut `None`, le prix est efface via `price_explicitly_cleared`).

- `DELETE /v1/trips/{tripId}/accommodations/{accommodationId}` — Suppression. Owner only. Retourne 204.

#### Recherche hotels Amadeus

- `GET /v1/travel/hotels/by-city` — Recherche d'hotels par ville. Params : `cityCode` (IATA obligatoire), `radius?`, `radiusUnit?` (KM/MILE), `ratings?` (etoiles separees par virgule), `hotelSource?` (ALL/BEDBANK/DIRECTCHAIN). Proxy vers Amadeus GET `/v1/reference-data/locations/hotels/by-city`.

- `GET /v1/travel/hotels/offers` — Offres d'hotels avec prix. Params : `hotelIds` (IDs separes par virgule, max 50), `checkInDate?`, `checkOutDate?`, `adults?` (defaut 1), `currency?`. Proxy vers Amadeus GET `/v3/shopping/hotel-offers`.

### Integration Amadeus Hotels (`api/src/integrations/amadeus/hotels.py`)

- `search_hotel_list(query)` : Appel Amadeus `/v1/reference-data/locations/hotels/by-city`. Retourne `HotelListResponse` contenant une liste de `HotelListItem` (chainCode, iataCode, name, hotelId, geoCode, address). Timeout 15s.

- `search_hotel_offers(query)` : Appel Amadeus `/v3/shopping/hotel-offers`. Parse les resultats en `HotelOfferResult` contenant hotel (dict), available (bool), et liste de `HotelOffer` (id, checkInDate, checkOutDate, room, guests, price). Timeout 20s.

### Schemas de reponse hotels

```
HotelListItemResponse :
  hotelId, name, chainCode?, iataCode?, dupeId?, geoCode?, address?, lastUpdate?

HotelOfferResultResponse :
  type, hotel (dict), available, offers[] :
    id?, checkInDate?, checkOutDate?, room?, guests?, price (currency, base, total)
```

### Modele SQLAlchemy

`Accommodation` (`api/src/models/accommodation.py`) :
- `id` (UUID, PK)
- `trip_id` (FK vers trips)
- `name` (String, not null)
- `address`, `check_in`, `check_out`, `price_per_night` (Numeric), `currency`, `booking_reference`, `notes`
- `created_at`, `updated_at`

### Service `AccommodationsService`

`api/src/services/accommodations_service.py` — Operations CRUD avec verification que le trip n'est pas COMPLETED avant toute modification.

### Permissions

- Owner : CRUD complet + recherche hotel
- Viewer : lecture seule, prix/devise/reference masques

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Booking hotel Amadeus | La recherche d'hotels et la consultation d'offres sont implementees, mais il n'y a pas de flux de reservation hotel (pas de `BookingIntent` type hotel, pas de `HotelOrder`). L'utilisateur ne peut que voir les prix et creer manuellement un hebergement. | P1 |
| Suggestions IA — endpoint backend | L'event `SuggestAccommodations` appelle `repository.suggestAccommodations()` mais l'endpoint backend dedie pour les suggestions d'hebergement IA n'est pas visible dans les routes `accommodations/routes.py`. A verifier si c'est gere par un endpoint AI generique. | P1 |
| Pas de lien hotel → accommodation | Quand un utilisateur trouve un hotel via la recherche Amadeus, il n'y a pas de flux automatique pour pre-remplir le formulaire `CreateAccommodation` avec les donnees de l'hotel (nom, adresse, prix). | P2 |
| Photos hotels | Les reponses Amadeus ne contiennent pas de photos. Pas d'integration avec une API de photos (Unsplash est present dans les integrations mais pour les trips, pas les hotels). | P2 |
| Tests widget HotelSearchSheet | Pas de fichier de test dedie pour `HotelSearchSheet` dans `test/accommodations/`. | P2 |
| Tests bloc AccommodationBloc hotel events | Le test `accommodation_bloc_test.dart` existe mais ne couvre potentiellement pas les events `SearchHotels`, `SearchHotelOffers`, `ClearHotelSearch`. | P2 |
| Carte map des hebergements | Pas de vue cartographique pour visualiser les hebergements du trip sur une carte. | P2 |
