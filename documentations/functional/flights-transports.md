# Vols et Transports

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

La feature Vols couvre tout le cycle de vie d'un transport aerien : recherche
multi-criteres via Amadeus, persistance par trip, recherche multi-destination,
repricing pre-booking, vols manuels (CRUD sans Amadeus), enrichissement temps reel
via AirLabs (statut, gates, retards), booking complet Stripe + Amadeus Flight Order.

Cote mobile : `FlightSearchForm` multi-mode, liste de resultats avec tri / filtres,
`FlightResultDetailsPage` avec bouton "Book", `ReplaceSearchSheet` pour swapper un
vol existant.

Cote backend, deux flux coexistent : proxy stateless `/v1/travel/flight/offers`
(cache 15 min en memoire, recherche hors trip) et flux persiste
`/v1/trips/{tripId}/flights/searches` (stocke recherche + offres en DB pour
repricing et booking ulterieurs). Deux types de vols cohabitent : `MAIN` (aller /
retour structurants) et `INTERNAL` (segments multi-destination).

---

## Cote Backend

### Recherches persistees

Routes : `api/src/api/flights/searches/routes.py`. Service :
`api/src/services/flight_search_service.py`.

- `POST /v1/trips/{tripId}/flights/searches` (201, editor-only) : appelle Amadeus
  `search_flight_offers`, persiste la `FlightSearch` + N `FlightOffer`. Body :
  `originIata`, `destinationIata`, `departureDate`, `returnDate?`, `adults`
  (1-9), `children?`, `infants?`, `travelClass?`, `nonStop?`, `currency?`.
  Reponse : `searchId` + `offers[]` (id, grandTotal, currency, stops calcules
  depuis `itineraries[0].segments.length - 1`).
- `GET /v1/trips/{tripId}/flights/searches/{searchId}` : recharge la recherche.
  Pour les viewers, `grandTotal` et `baseTotal` sont masques (None), seule la
  devise reste visible.
- `POST /v1/trips/{tripId}/flights/searches/multi` (201) : multi-segment.
  Appels Amadeus en parallele via `asyncio.gather(..., return_exceptions=True)`,
  un segment qui echoue est skip gracefully. Chaque segment produit sa
  `FlightSearch` + ses offres ; reponse `MultiDestSearchResponse`.

La persistance stocke `amadeus_request` et `amadeus_response` brutes pour
rejouer / debug.

### Offres de vol

Routes : `api/src/api/flights/offers/routes.py`. Service :
`api/src/services/flight_offer_pricing_service.py`.

- `GET /v1/trips/{tripId}/flights/offers/{offerDbId}` : renvoie le `offer_json`
  Amadeus stocke. Pour les viewers, le bloc `price` est ecrase par
  `{currency: <X>}` (shallow-copy pour ne pas muter le JSON en DB).
- `POST /v1/trips/{tripId}/flights/offers/{offerDbId}/price` (editor-only) :
  repricing pre-booking. Reconstruit un objet `FlightOffer` depuis `offer_json`,
  appelle `amadeus_client.confirm_flight_price(...)`, met a jour `grand_total`
  + `currency`, stocke la reponse dans `priced_offer_json`. Ce JSON est ensuite
  envoye au Flight Order create.

### Vols manuels (CRUD sans Amadeus)

Routes : `api/src/api/flights/manual/routes.py`. Service :
`api/src/services/manual_flight_service.py`.

- `POST /v1/trips/{tripId}/flights/manual` (201) : creation. Champs :
  `flightNumber` (upper + trim, obligatoire), `airline?`, `departureAirport?`,
  `arrivalAirport?`, `departureDate?`, `arrivalDate?`, `price?` (Decimal),
  `currency?`, `notes?`, `flightType` (`MAIN`/`INTERNAL`). Si `price` est
  fourni, un `BudgetItem` lie est cree (`category=FLIGHT`, `source_type=
  manual_flight`, `is_planned=True`).
- `GET /v1/trips/{tripId}/flights/manual` : liste.
- `GET /v1/trips/{tripId}/flights/manual/{flightId}` : detail.
- `PATCH /v1/trips/{tripId}/flights/manual/{flightId}` : update partiel. Router
  fait le field mapping camel -> snake et passe les seuls champs set
  (`model_dump(exclude_unset=True)`). Le service synchronise le `BudgetItem`
  lie : update si present, creation si absent, delete si `price=None`. Sentinel
  `Decimal | None = ...` pour distinguer "pas touche" et "passe a null".
- `DELETE /v1/trips/{tripId}/flights/manual/{flightId}` (204) : suppression
  cascade du `BudgetItem` lie avant le delete du vol.

Garde commune : `_check_trip_not_completed(trip)` refuse les mutations avec
`TRIP_COMPLETED` 403 sur trip `COMPLETED`.

### Infos temps reel (AirLabs)

Routes : `api/src/api/flights/info/routes.py`. Service :
`api/src/services/airlabs_service.py` (facade mince sur le client).

- `GET /v1/travel/flights/{flightNumber}/info` : lookup AirLabs. Validation
  regex IATA `^[A-Z0-9]{2}\d{1,4}$` (ex. `AF1234`). 503
  `AIRLABS_NOT_CONFIGURED` si `AIRLABS_API_KEY` absent. Reponse : `flightIata`,
  `airlineIata`, `airlineName`, `status`, et pour depart/arrivee : `iata`,
  `terminal`, `gate`, `time`, `actual`, `delay`.

Le client AirLabs maintient un cache memoire TTL 5 min, aucune persistance DB.

### Flight Orders (booking confirme)

Routes : `api/src/api/flights/orders/routes.py`.

- `GET /v1/trips/{tripId}/flights/orders` : liste les commandes confirmees ou
  annulees. Les viewers ne voient pas `paymentId`.
- `GET /v1/trips/{tripId}/flights/orders/{orderId}` : detail.
- `DELETE /v1/trips/{tripId}/flights/orders/{orderId}` (204) : suppression.
  Erreur `CONFIRMED_FLIGHT_IMMUTABLE` 403 si `status == CONFIRMED` ("Un vol
  confirme ne peut pas etre supprime. Contactez la compagnie pour une
  annulation.").

### Booking flow (intent + Stripe + Amadeus)

Service : `api/src/services/booking_orchestrator_service.py`. Flow complet
documente dans `booking-flow.md` ; cote vols :

1. Mobile cree un `BookingIntent` (type=`FLIGHT`, `selected_offer_id`) via
   `POST /v1/trips/{tripId}/booking-intents`.
2. Authorize Stripe : `POST /v1/booking-intents/{id}/authorize` cree un
   PaymentIntent (capture=manual). Statut passe a `AUTHORIZED`.
3. `POST /v1/booking-intents/{id}/book` appelle
   `BookingOrchestratorService.book(...)` avec `traveler_ids` + `contacts` :
   - check `AUTHORIZED` -> passe en `BOOKING_PENDING`,
   - charge l'offre (priorise `priced_offer_json` sinon `offer_json`),
   - charge les `TripTraveler`, mappe en `FlightOrderTraveler` via
     `TravelersService.traveler_to_amadeus_payload`,
   - appelle `amadeus_client.create_flight_order(...)`,
   - extrait `amadeus_order_id` (`AMADEUS_ERROR` 500 si absent) et un
     `ticket_url` (`amadeus://order/{id}`) si `associatedRecords` contient
     `originSystemCode=GDS`,
   - bloc atomique `unit_of_work(db)` : `FlightOrder` (status=CONFIRMED) +
     `BudgetItem` (`is_planned=False`, source_type=`flight_order`) + set
     `booking_intent.amadeus_order_id`,
   - exception -> rollback DB, statut intent `FAILED`, `last_error` stocke.

Helper `_extract_flight_metadata` pull (origin, destination, departure_date)
depuis `itineraries[0].segments[0/-1]` pour labelliser le budget item
("Vol : CDG -> NRT"). Fallback ("", "", None) si la shape Amadeus diverge.

### Proxy Amadeus stateless

Routes : `api/src/api/travel/routes.py`.

- `GET /v1/travel/flight/offers` : proxy direct vers Amadeus + validation
  (adults 1-9, infants <= adults, includedAirlineCodes XOR
  excludedAirlineCodes, max 1-250). Cache TTL 15 min memoire
  (`cachetools.TTLCache`, 256 entries, key sha256 des params).
- `GET /v1/travel/flight/destinations` : Flight Inspiration Search.
- `GET /v1/travel/flight/cheapest-dates` : Flight Cheapest Date Search.
- `GET /v1/travel/locations[/nearest|/{id}]` : recherche aeroports / villes
  via `aviation_data_service` (donnees offline embarquees).

### Modeles SQLAlchemy

- `FlightSearch` : trip_id, origin/destination_iata, dates, pax, travel_class,
  non_stop, currency, amadeus_request/response (JSONB).
- `FlightOffer` : trip_id, flight_search_id, amadeus_offer_id, source,
  validating_airline_codes, currency, grand_total, base_total, offer_json,
  priced_offer_json.
- `FlightOrder` : trip_id, flight_offer_id, booking_intent_id,
  amadeus_flight_order_id, status (`FlightOrderStatus`), booking_reference,
  payment_id, ticket_url, amadeus_create_order_request/response.
- `ManualFlight` : trip_id, flight_number, airline, departure/arrival_airport,
  dates, price, currency, notes, flight_type (`MAIN`/`INTERNAL`).

### Permissions

Toutes les routes trip-scoped passent par `TripAccess`
(`api/src/api/auth/trip_access.py`) : `get_trip_access` (lecture),
`get_trip_editor_access` (mutation). Masquage prix systematique pour
`TripRole.VIEWER` sur offres + orders.

---

## Cote Mobile

### Formulaire de recherche

`bagtrip/lib/flight_search/view/flight_search_form.dart`. BLoC :
`bagtrip/lib/flight_search/bloc/flight_search_bloc.dart`.

`FlightSearchForm` est un `ListView` BLoCConsumer compose de
`ManualFlightHeader`, `TripTypeSelector` (3 modes : 0 = aller simple, 1 =
aller-retour, 2 = multi-destination), `ManualFlightAirportsCard` +
`ManualFlightDateCards` (modes 0/1) ou `MultiDestinationForm` (mode 2),
`ManualFlightCabinSelector` (ECONOMY / PREMIUM_ECONOMY / BUSINESS),
`ManualFlightTripDetailsCard` (adultes / enfants / bebes + prix max), CTA
degrade.

Events principaux : `SearchDepartureAirport`, `SearchArrivalAirport`,
`SetTripType`, `Set{Adults,Children,Infants,TravelClass}`,
`Select{Departure,Arrival}Airport`, `Set{Departure,Return}Date`, `SetMaxPrice`,
`{Add,Remove}FlightSegment`, `SelectMultiDest{Departure,Arrival}Airport`,
`SetMultiDestDate`, `ShowValidationErrors`, `SwapAirports`,
`InitWithPrefilledData`.

Specificite multi-destination : `AddFlightSegment` chaine automatiquement
l'arrivee du segment N comme depart du segment N+1.

Au submit, le form construit un `FlightSearchArguments`. Si `onSubmit` est
fourni (cas replace), il delegue au caller sans naviguer ; sinon push vers
`FlightSearchResultRoute`. En cas de champs invalides : `ShowValidationErrors`
+ snackbar.

### Resultats de recherche

`FlightSearchResultBloc` charge via `LocationService.searchFlights()` qui frappe
le proxy stateless `/v1/travel/flight/offers`. Le parsing passe par
`Flight.fromAmadeusJson()` : horaires + IATA outbound/return, duree ISO formatee
("PT1H30M" -> "1h30"), compagnie via dictionnaire `carriers` (fallback IATA),
type avion via `aircraft`, prix `grandTotal`/`base`, classe cabine/booking,
bagages inclus (`BaggageInfo`), nombre d'escales (segments - 1).

Filtres (event `ApplyFilters`) : tri par prix asc/desc, compagnie, bagages
cabine, bagages soute, plage horaire depart. Navigation J-1/J+1 via
`SelectDate` qui conserve la duree de voyage.

### Details d'une offre

`bagtrip/lib/flight_result_details/view/flight_result_details_page.dart` +
view + `FlightResultDetailsBloc` (holder simple).

La view rend 4 cards : `FlightDetailCard` (outbound + retour si present, tag
stops `secondary`/`warning`), `BaggageInfoCard` (cabine + soute),
`ClassInfoCard` (cabine + booking + fare basis), `FareInfoCard` (prix, base,
places dispo, date limite ticketing).

Bouton `bookFlight` visible si `flight.tripId != null &&
flight.flightOfferId != null`. Au tap : `CreateBookingIntent(tripId,
flightOfferId)` au `BookingBloc`. Listener : `PaymentSheetReady ->
PresentPaymentSheet`, `PaymentSuccess -> PaymentSuccessRoute`,
`PaymentCancelled` / `PaymentFailed -> snackbar`.

### Replace flight flow

Composant cle : `ReplaceSearchSheet`
(`bagtrip/lib/design/widgets/replace_search_sheet.dart`) + helper
`showReplaceSearchSheet(...)`. Scaffold reutilisable pour tout
search-and-replace trip-detail (vols, hotels) :

- modal bottom sheet 95% hauteur,
- `isDismissible: false`, `enableDrag: false` (pas de dismiss tap-outside pour
  ne pas perdre l'etat de recherche),
- header titre + sous-titre + close, handle bar 40x4, contenu = `child`.

Cote panel flights (`trip_detail/view/panels/flights_panel.dart`), tap
"Replace" -> sheet ouvre un `FlightSearchForm` avec `onSubmit` custom qui
ajoute `replaceFlightId: flight.id` aux `FlightSearchArguments`. Apres
selection de la nouvelle offre -> dispatch `ReplaceFlightFromDetail(oldFlightId,
newFlightData)` au `TripDetailBloc`.

Handler atomique
(`trip_detail/bloc/trip_detail_transport_handlers.dart::_onReplaceFlight`) :

1. Snapshot de la liste originale.
2. Optimistic UI : retrait du vieux vol + recompute `completionResult`.
3. `DELETE /flights/manual/{old}` : echec -> restore snapshot + emit
   `operationError`.
4. `POST /flights/manual` : succes -> append + recompute ; echec -> rollback
   total + `operationError`.

`operationError` emis puis immediatement clear via `clearOperationError` ->
snackbar transient sans coller le state.

### Boarding pass UI

`FlightBoardingPassCard` (`bagtrip/lib/trip_detail/widgets/`) : carte
boarding-pass stylisee pour un vol manuel. Zone numero + compagnie + badge
statut (`deriveFlightStatus`), zone codes IATA grands + horaires + icone avion,
zone date + prix, ligne de perforation avec encoches laterales.
Swipe-to-delete (Dismissible) owners only sur trips non completes. Animation
scale 0.98 -> 1.0 a la pression.

### Repository transports

`bagtrip/lib/repositories/transport_repository.dart`. Methodes :
`createManualFlight`, `getManualFlights`, `deleteManualFlight`,
`updateManualFlight`, `lookupFlight` (`FlightInfo` AirLabs, debounce 800 ms
sur 4+ caracteres dans `ManualFlightForm`), `searchFlightsPersisted`,
`searchMultiDestFlights`. Retour systematique en `Future<Result<T>>` (jamais
de throw).

---

## Integration Amadeus

Wrapper : `api/src/services/amadeus_service.py` (facade mince). Client :
`api/src/integrations/amadeus/`.

- `auth.py` : OAuth2 client credentials avec cache token (refresh auto).
- `flights.py` : `search_flight_offers`, `search_flight_destinations`
  (inspiration), `search_flight_cheapest_dates`, `confirm_flight_price`
  (pricing), `create_flight_order` (booking).
- `locations.py` : recherche aeroports / villes (utilise par d'autres flows ;
  les routes `/travel/locations` passent par `aviation_data_service` offline).
- Timeouts : 20s offres, 15s destinations / cheapest dates, 30s create order.

Cache : proxy `/travel/flight/offers` -> `TTLCache` 15 min memoire (256
entries). Pas de cache cote search persistee (fraicheur des prix pre-booking).

Layering : routes -> `AmadeusService` (jamais `amadeus_client` direct depuis
une route, regle CLAUDE.md). Les services metier (`FlightSearchService`,
`FlightOfferPricingService`, `BookingOrchestratorService`) appellent
`amadeus_client` directement (couche en aval du wrapper).

---

## Flux

### Recherche -> selection -> booking 3DS

1. Utilisateur ouvre `FlightSearchForm` -> submit -> navigation vers
   `FlightSearchResultRoute` avec `FlightSearchArguments`.
2. `FlightSearchResultBloc` charge via proxy `/v1/travel/flight/offers`.
3. Tap sur une carte -> push `FlightResultDetailsRoute(flight)`. Si
   `tripId + flightOfferId` presents, bouton Book visible.
4. Tap Book -> `CreateBookingIntent` -> backend cree `BookingIntent` +
   PaymentIntent Stripe -> `PaymentSheetReady`.
5. `PresentPaymentSheet` -> Stripe SDK (Apple Pay / cards / 3DS).
6. Apres succes 3DS -> `CapturePayment` -> backend appelle
   `BookingOrchestratorService.book()` -> create flight order Amadeus +
   `FlightOrder` + `BudgetItem` atomiques (`unit_of_work`).
7. `PaymentSuccess(intentId)` -> `PaymentSuccessRoute`.

### Replace flight (atomic DELETE + CREATE)

1. Trip detail panel flights -> menu contextuel "Replace" sur un vol existant.
2. `showReplaceSearchSheet(...)` ouvre un `FlightSearchForm` avec `onSubmit`
   custom + `replaceFlightId`.
3. Selection de la nouvelle offre -> `ReplaceFlightFromDetail`.
4. Handler atomique : optimistic prune -> DELETE old -> CREATE new ->
   rollback complet si echec sur l'une des deux operations.

### Ajout d'un vol manuel

1. "Ajouter un vol" -> `ManualFlightForm`.
2. Saisie du numero -> debounce 800 ms -> `LookupFlightInfo` -> AirLabs
   preremplit airline / depart / arrivee / horaires.
3. Ajustement prix, type (MAIN/INTERNAL), notes.
4. Submit -> `POST /flights/manual` -> creation + `BudgetItem` lie auto.
5. Trip detail recompute completion, `BudgetItem` apparait dans budget
   categorie `FLIGHT`.

### Multi-destination

1. Mode 2 `TripTypeSelector` -> `MultiDestinationForm`.
2. `AddFlightSegment` chaine automatiquement depart N+1 = arrivee N.
3. Submit -> `POST /v1/trips/{id}/flights/searches/multi`.
4. Backend lance N appels Amadeus en parallele
   (`asyncio.gather(..., return_exceptions=True)`), persiste segment par
   segment. Un segment qui echoue est skip sans casser les autres.
5. Reponse `MultiDestSearchResponse` (liste de `FlightSearchResponse`).

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Update vol manuel cote mobile | Route PATCH et service backend existent, mais `TransportRepository.updateManualFlight` n'est pas branche dans `ManualFlightForm` (pas de mode edition). Aujourd'hui = delete + recreate. | P1 |
| Persistance recherches cote mobile | Le mobile utilise le proxy stateless `/v1/travel/flight/offers` plutot que `POST /trips/{id}/flights/searches`. Les deux flux coexistent, l'historique persiste n'est pas exploite. | P1 |
| Tests blocs results / details / booking | Pas de fichier de test pour `FlightSearchResultBloc`, `FlightResultDetailsBloc`, `BookingBloc`. Le `FlightSearchBloc` est couvert. | P2 |
| Gestion erreurs Stripe avancee | `BookingBloc` ne gere que `FailureCode.Canceled`. Pas de retry, pas de differenciation des erreurs reseau / decline / 3DS. | P2 |
| Boarding pass QR / billet | `FlightBoardingPassCard` purement visuel : pas de QR, pas de lien vers le billet electronique, `ticket_url` Amadeus (`amadeus://order/...`) non exploite. | P2 |
| AirLabs : pas de persistance | Lookups non persistes ni rafraichis en arriere-plan (cache memoire TTL 5 min seulement). Pas de notification proactive en cas de delay / cancellation. | P2 |
| Cancellation flight order | La route DELETE refuse les ordres `CONFIRMED`. Pas de flow d'annulation Amadeus expose. | P3 |
