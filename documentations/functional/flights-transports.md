# Vols et Transports

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

La feature Vols & Transports couvre l'ensemble du cycle de vie des vols dans BagTrip : recherche de vols via Amadeus, consultation des resultats et details, creation de vols manuels, suivi temps reel via AirLabs, affichage boarding-pass et gestion du booking (intent, paiement Stripe, confirmation Amadeus). Le systeme distingue deux types de vols : MAIN (vols principaux aller/retour) et INTERNAL (vols internes au sejour).

---

## Architecture mobile (Flutter)

### BLoCs

Le parcours vol est decoupe en 4 BLoCs independants :

| BLoC | Fichier | Role |
|------|---------|------|
| `FlightSearchBloc` | `bagtrip/lib/flight_search/bloc/flight_search_bloc.dart` | Formulaire de recherche : selection aeroports, dates, passagers, classe, multi-destination |
| `FlightSearchResultBloc` | `bagtrip/lib/flight_search_result/bloc/flight_search_result_bloc.dart` | Chargement, filtrage et tri des resultats de recherche |
| `FlightResultDetailsBloc` | `bagtrip/lib/flight_result_details/bloc/flight_result_details_bloc.dart` | Affichage des details d'une offre selectionnee |
| `TransportBloc` | `bagtrip/lib/transports/bloc/transport_bloc.dart` | CRUD vols manuels + lookup AirLabs |
| `BookingBloc` | `bagtrip/lib/booking/bloc/booking_bloc.dart` | Paiement Stripe (authorize, present sheet, capture) |

### Formulaire de recherche

Le `FlightSearchForm` (`bagtrip/lib/flight_search/view/flight_search_form.dart`) propose trois modes via `TripTypeSelector` :

- **Aller simple** (index 0) : depart + arrivee + date de depart
- **Aller-retour** (index 1) : idem + date de retour
- **Multi-destinations** (index 2) : liste de `FlightSegment` avec chainage automatique (l'arrivee du segment N devient le depart du segment N+1)

Champs du formulaire :
- Aeroports depart/arrivee avec autocompletion via `LocationService.searchLocationsByKeyword()` (type `AIRPORT`)
- Dates depart/retour
- Nombre de passagers (adultes, enfants, bebes)
- Classe de voyage (ECONOMY, PREMIUM_ECONOMY, BUSINESS, FIRST) via index
- Prix maximum optionnel
- Swap aeroports (event `SwapAirports`)
- Pre-remplissage via `InitWithPrefilledData` (utilise pour les liens depuis le trip detail)

Le modele `FlightSearchPrefill` (`bagtrip/lib/flight_search/models/flight_search_prefill.dart`) porte `originIata`, `destinationIata`, `departureDate`, `returnDate`, `nbTravelers`.

### Resultats de recherche

`FlightSearchResultBloc` appelle `LocationService.searchFlights()` qui fait un GET sur `{baseUrl}/travel/flight/offers` (endpoint proxy vers Amadeus).

Les resultats sont parses via `Flight.fromAmadeusJson()` (`bagtrip/lib/flight_search_result/models/flight.dart`) qui extrait :
- Horaires et codes IATA de depart/arrivee (outbound + return si aller-retour)
- Duree ISO 8601 formatee (PT1H30M -> 1h30)
- Compagnie via dictionnaire `carriers`
- Type avion via dictionnaire `aircraft`
- Prix (grandTotal, base)
- Classe de cabine, classe de booking, base tarifaire
- Bagages inclus (`BaggageInfo` : quantite, poids, unite)
- Nombre d'escales (segments - 1)

**Filtres disponibles** (event `ApplyFilters`) :
- Tri par prix (lowest/highest)
- Filtre par compagnie aerienne
- Bagages cabine inclus
- Bagages soute inclus
- Heure de depart (avant/apres)

**Navigation par date** : l'event `SelectDate` permet de relancer la recherche sur la veille ou le lendemain, en recalculant la date retour pour conserver la meme duree de voyage.

### Details d'une offre

`FlightResultDetailsBloc` est un simple holder qui stocke le `Flight` selectionne. La vue (`bagtrip/lib/flight_result_details/view/flight_result_details_view.dart`) affiche 4 cartes :
- `FlightDetailCard` : horaires, route, escales
- `BaggageInfoCard` : bagages cabine/soute inclus
- `ClassInfoCard` : cabine, classe de booking, base tarifaire
- `FareInfoCard` : prix base, prix total, places disponibles, date limite de ticketing

### Vols manuels

Le `TransportBloc` gere le CRUD des vols manuels via `TransportRepository` :

| Event | Action |
|-------|--------|
| `LoadTransports` | Charge tous les vols manuels du trip, separes en `mainFlights` (MAIN) et `internalFlights` (INTERNAL) |
| `CreateManualFlight` | Cree un vol avec : flightNumber (obligatoire), airline, airports, dates, price, notes, flightType |
| `DeleteManualFlight` | Supprime un vol (owner only) |
| `LookupFlightInfo` | Auto-completion via AirLabs (declenche apres 800ms de debounce sur 4+ caracteres) |

Le `ManualFlightForm` (`bagtrip/lib/transports/widgets/manual_flight_form.dart`) est structure en 3 sections :
1. **Route** : aeroports depart/arrivee + numero de vol avec lookup automatique
2. **Schedule** : dates depart/arrivee avec date+time pickers adaptatifs
3. **Details** : compagnie, type (MAIN/INTERNAL via SegmentedButton), prix, notes

Validations cote mobile :
- Numero de vol obligatoire
- Aeroports depart et arrivee doivent etre differents
- Date d'arrivee doit etre apres la date de depart

### Boarding Pass

Le `FlightBoardingPassCard` (`bagtrip/lib/trip_detail/widgets/flight_boarding_pass_card.dart`) affiche un vol manuel sous forme de carte boarding-pass stylisee avec :
- Zone 1 : numero de vol + compagnie + badge de statut (derive via `deriveFlightStatus`)
- Zone 2 : codes IATA depart/arrivee en gros + horaires + duree + icone avion
- Zone 3 : date + prix
- Ligne de perforation avec encoches laterales (notches circulaires)
- Swipe-to-delete (Dismissible) pour les owners sur les trips non completes
- Animation de pression (scale 0.98 -> 1.0)

### Booking (reservation)

Le `BookingBloc` orchestre le paiement via Stripe :
1. `AuthorizePayment` -> appel backend -> recoit `clientSecret`
2. `PresentPaymentSheet` -> Stripe SDK (`initPaymentSheet` + `presentPaymentSheet`)
3. `CapturePayment` -> confirmation backend

Etats : `PaymentAuthorizing` -> `PaymentSheetReady` -> `PaymentSuccess` / `PaymentCancelled` / `PaymentFailed`

---

## Architecture backend (FastAPI)

### Endpoints vols

#### Recherche de localisations
- `GET /v1/travel/locations?keyword=&subType=AIRPORT` — Proxy vers Amadeus Reference Data Locations, avec cache memoire cote mobile (`_searchCache`)

#### Recherche de vols (proxy Amadeus)
- `GET /v1/travel/flight/offers` — Proxy vers Amadeus GET `/v2/shopping/flight-offers`, parametres : originLocationCode, destinationLocationCode, departureDate, returnDate, adults, children, infants, travelClass, currencyCode

#### Recherches persistees
- `POST /v1/trips/{tripId}/flights/searches` — Cree une recherche, appelle Amadeus, persiste le `FlightSearch` + N `FlightOffer` en base. Requete : `originIata` (3 chars), `destinationIata`, `departureDate`, `returnDate?`, `adults` (1-9), `children?`, `infants?`, `travelClass?`, `nonStop?`, `currency?`. Retourne `searchId` + liste de `FlightOfferSummary` (id, grandTotal, currency, stops).
- `GET /v1/trips/{tripId}/flights/searches/{searchId}` — Details d'une recherche avec toutes les offres. Les viewers n'ont pas acces aux prix (grandTotal/baseTotal masques).

#### Offres de vol
- `GET /v1/trips/{tripId}/flights/offers/{offerDbId}` — Recupere le JSON complet d'une offre. Les viewers n'ont acces qu'a la devise (prix masques).
- `POST /v1/trips/{tripId}/flights/offers/{offerDbId}/price` — Repricing via Amadeus Pricing API (owner only). Appelle `FlightOfferPricingService`.

#### Commandes de vol (flight orders)
- `GET /v1/trips/{tripId}/flights/orders` — Liste les commandes. Les viewers ne voient pas le paymentId.
- `GET /v1/trips/{tripId}/flights/orders/{orderId}` — Detail d'une commande.
- `DELETE /v1/trips/{tripId}/flights/orders/{orderId}` — Suppression (impossible si statut CONFIRMED : erreur `CONFIRMED_FLIGHT_IMMUTABLE`).

#### Vols manuels
- `POST /v1/trips/{tripId}/flights/manual` — Cree un vol manuel. Champs : flightNumber (obligatoire), airline, departureAirport, arrivalAirport, departureDate, arrivalDate, price (Decimal), currency, notes, flightType (MAIN/INTERNAL).
- `GET /v1/trips/{tripId}/flights/manual` — Liste tous les vols manuels.
- `GET /v1/trips/{tripId}/flights/manual/{flightId}` — Detail.
- `DELETE /v1/trips/{tripId}/flights/manual/{flightId}` — Suppression (owner only).

#### Info vol temps reel
- `GET /v1/travel/flights/{flightNumber}/info` — Lookup AirLabs. Validation regex IATA : `^[A-Z0-9]{2}\d{1,4}$`. Retourne : flightIata, airlineIata, airlineName, status, departure/arrival (iata, terminal, gate, time, actual, delay).

#### Booking Intents
- `POST /v1/trips/{tripId}/booking-intents` — Cree un intent (type: `flight`), lie a une `flightOfferId`. Retourne id, type, status (INIT), amount, currency, selectedOfferId.
- `GET /v1/booking-intents/{intentId}` — Recupere un intent.
- `POST /v1/booking-intents/{intentId}/book` — Booking effectif via `BookingOrchestratorService`. Requete : `travelerIds` + `contacts`. Retourne : bookingIntent (id, status) + amadeus (type, orderId).

### Integrations externes

#### Amadeus (`api/src/integrations/amadeus/`)
- **Auth** (`auth.py`) : OAuth2 client credentials, token cache
- **Flights** (`flights.py`) : `search_flight_offers`, `search_flight_destinations` (inspiration), `search_flight_cheapest_dates`, `confirm_flight_price` (POST pricing), `create_flight_order` (POST booking)
- **Locations** (`locations.py`) : `search_locations_by_keyword`, `search_location_by_id`, `search_location_nearest`
- Timeout : 20s pour les offres, 15s pour les destinations/dates, 30s pour les bookings

#### AirLabs (`api/src/integrations/airlabs/client.py`)
- `AirLabsClient.lookup_flight(flight_iata)` : GET `https://airlabs.co/api/v9/flight`
- Cache memoire avec TTL de 5 minutes
- Requires `AIRLABS_API_KEY` dans les settings

### Modeles SQLAlchemy
- `FlightSearch` (`api/src/models/flight_search.py`) : origin_iata, destination_iata, departure_date, return_date, adults, etc.
- `FlightOffer` (`api/src/models/flight_offer.py`) : trip_id, amadeus_offer_id, offer_json (JSONB), grand_total, base_total, currency, priced_offer_json
- `FlightOrder` (`api/src/models/flight_order.py`) : trip_id, status (CONFIRMED/CANCELLED), booking_reference, payment_id, ticket_url
- `ManualFlight` (`api/src/models/manual_flight.py`) : trip_id, flight_number, airline, airports, dates, price, currency, notes, flight_type (MAIN/INTERNAL)
- `BookingIntent` (`api/src/models/booking_intent.py`) : trip_id, user_id, type, status, amount, currency, selected_offer_id, amadeus_order_id

### Permissions (TripAccess)

Toutes les routes vols utilisent le systeme `TripAccess` (`api/src/api/auth/trip_access.py`) :
- **Owner** : lecture + ecriture (CRUD, pricing, booking)
- **Viewer** : lecture seule, prix masques sur les offres et orders

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Multi-destination backend | Le `LocationService.searchFlights()` a un TODO explicite : "Implement multi-destination search when backend supports it". Le formulaire multi-dest est complet cote Flutter mais la recherche backend ne prend qu'un seul segment. (`bagtrip/lib/service/location_service.dart:29`) | P1 |
| Update vol manuel | Le `ManualFlightService` cote API ne propose pas de route PATCH/PUT pour modifier un vol manuel existant. Le `TransportRepository` Flutter n'expose pas non plus de methode update. | P1 |
| Tests bloc FlightSearchResult | Pas de fichier de test dedie pour `FlightSearchResultBloc` (le `FlightSearchBloc` a un test dans `test/blocs/flight_search_bloc_test.dart`). | P2 |
| Tests bloc FlightResultDetails | Pas de fichier de test pour `FlightResultDetailsBloc`. | P2 |
| Tests bloc Booking | Pas de fichier de test pour `BookingBloc`. | P2 |
| Persistence des recherches cote mobile | Le mobile utilise le endpoint proxy `/travel/flight/offers` (non persiste) plutot que le endpoint persiste `POST /trips/{id}/flights/searches`. Les deux flux coexistent sans integration. | P1 |
| Gestion erreurs Stripe avancee | Le `BookingBloc` ne gere que `FailureCode.Canceled` — pas de retry ni de gestion des erreurs reseau specifiques Stripe. | P2 |
| Boarding pass QR code | Le `FlightBoardingPassCard` est un affichage visuel pur — pas de QR code, pas de scan, pas de lien vers un billet electronique. | P2 |
