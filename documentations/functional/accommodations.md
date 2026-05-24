# Hebergements

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

La feature Hebergements gere les logements rattaches a un trip BagTrip. Elle couvre la saisie manuelle, la recherche d'hotels via Amadeus (search-only, sans booking), les suggestions IA contextualisees, et la synchronisation automatique avec le budget. Chaque hebergement porte un `validation_status` (SUGGESTED / VALIDATED / MANUAL) qui pilote l'affichage du `ItemStatusChip` et le flow Validate/Replace du panel trip-detail.

Le booking d'hotel via Amadeus n'est volontairement pas implemente : l'utilisateur reserve sur la plateforme de son choix, puis enregistre la reference dans BagTrip via le CRUD ou le flow Validate (saisie de la reference externe). Cette decision evite la complexite des conditions d'annulation, des PNR hoteliers et du paiement Amadeus pour un domaine ou la fragmentation des plateformes (Booking, Airbnb, sites officiels) est tres elevee.

La feature s'integre cote mobile au `HotelPanel` du trip-detail (canal principal) et a une `AccommodationsPage` autonome (legacy / debug). Cote backend, elle expose deux routeurs distincts : `/v1/trips/{tripId}/accommodations` pour le CRUD trip-scoped et `/v1/travel/hotels/*` pour la recherche Amadeus (auth JWT mais pas de scope trip, car la recherche peut etre faite avant la creation du voyage).

---

## Cote Backend

### CRUD accommodations (`api/src/api/accommodations/routes.py`)

Routeur monte sous `/v1/trips/{tripId}/accommodations`. Acces controles par `get_trip_editor_access` (Owner / Editor) sauf le GET qui passe par `get_trip_access` (Owner / Editor / Viewer).

| Methode | Endpoint | Acces | Description |
|---------|----------|-------|-------------|
| POST | `/v1/trips/{tripId}/accommodations` | Editor | Cree un hebergement, retourne 201. Body : `name`, `address?`, `checkIn?`, `checkOut?`, `pricePerNight?` (Decimal), `currency?`, `bookingReference?`, `notes?` |
| GET | `/v1/trips/{tripId}/accommodations` | Viewer | Liste les hebergements. Pour role VIEWER, masque `pricePerNight`, `currency` et `bookingReference` |
| POST | `/v1/trips/{tripId}/accommodations/suggest` | Editor + quota IA | Suggestions IA contextualisees, increment `PlanService.ai_generation` |
| PATCH | `/v1/trips/{tripId}/accommodations/{accommodationId}` | Editor | Mise a jour partielle. Si `pricePerNight` est dans `model_fields_set` avec valeur `None`, le prix est explicitement efface via `price_explicitly_cleared` |
| DELETE | `/v1/trips/{tripId}/accommodations/{accommodationId}` | Editor | Suppression, retourne 204 |

Toutes les operations passent par `AppError` mappe via `create_http_exception`. Pas de logique metier inline.

### Service `AccommodationsService`

`api/src/services/accommodations_service.py` centralise la logique. Operations protegees par `_check_trip_not_completed` : impossible de muter un trip `COMPLETED` (`AppError("TRIP_COMPLETED", 403)`). Le service expose des methodes statiques (pas d'etat interne) et toutes les ecritures se concluent par `db.commit()` + `db.refresh(entity)` pour garantir la coherence des IDs / timestamps cote reponse.

**Synchronisation budget automatique** :
- A la creation, si `price_per_night` est defini, un `BudgetItem` lie est cree avec `source_type="accommodation"`, `source_id=accommodation.id`, categorie `BudgetCategory.ACCOMMODATION`, montant `price_per_night * nights` (helper `_calc_nights`, minimum 1 nuit), `is_planned=True`, et `date=check_in` pour rattacher la depense au bon jour du voyage.
- A la mise a jour, le `BudgetItem` lie est resynchronise via `BudgetItemService.find_by_source`. Si aucun budget item n'existe encore (cas d'un hebergement cree sans prix puis enrichi), un nouveau est cree a la volee. Si le prix est efface explicitement (`price_explicitly_cleared`), le BudgetItem est supprime de la DB.
- A la suppression de l'hebergement, le `BudgetItem` lie est supprime en cascade applicative (pas de `ondelete=CASCADE` au niveau FK : le service est responsable).

**Suggestions IA (`suggest_accommodations`)** : assemble un prompt utilisateur localise (EN/FR via `_ACCOMMODATION_SUGGEST_LABELS`) avec destination, code IATA, duree, voyageurs, budget, et liste des hebergements existants pour eviter les doublons. Appel `LLMService.acall_llm` avec le template `accommodation_suggest` (rendu via `render(name, locale=resolved_locale)`). En cas d'echec LLM, retourne une liste vide (log via `logger.error` avec le message d'erreur), jamais de `raise` qui casserait l'UX. Les suggestions sont ensuite renvoyees telles quelles a la route, qui increment le compteur `PlanService.increment_ai_generation` pour facturer le quota.

### Recherche hotels Amadeus (`api/src/api/hotels/routes.py`)

Routeur monte sous `/v1/travel/hotels`. Auth par JWT standard (pas de scope trip). Search-only : aucun endpoint de booking n'est expose.

| Methode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/v1/travel/hotels/by-city` | Recherche par ville. Params : `cityCode` (IATA, obligatoire), `radius?`, `radiusUnit?` (KM/MILE), `ratings?` (etoiles separees virgule), `hotelSource?` (ALL/BEDBANK/DIRECTCHAIN) |
| GET | `/v1/travel/hotels/offers` | Offres avec prix. Params : `hotelIds` (max 50, separes virgule), `checkInDate?`, `checkOutDate?`, `adults?` (defaut 1), `currency?` |

Les deux endpoints delegate a `AmadeusService.search_hotel_list` et `search_hotel_offers` (`api/src/services/amadeus_service.py`), facades minces sur `amadeus_client`. La layering rule est respectee : la route ne touche jamais le client d'integration directement.

### Modele SQLAlchemy `Accommodation`

`api/src/models/accommodation.py`. Table `accommodations` :

| Colonne | Type | Note |
|---------|------|------|
| `id` | UUID | PK, `default=uuid.uuid4` |
| `trip_id` | UUID | FK -> `trips.id`, indexed |
| `name` | String | non-null |
| `address`, `notes`, `booking_reference` | String | nullable |
| `check_in`, `check_out` | DateTime(tz) | nullable |
| `price_per_night` | Numeric(12,2) | nullable |
| `currency` | String(3) | defaut `EUR` |
| `validation_status` | String | defaut `MANUAL` (server_default aussi), values : `SUGGESTED` / `VALIDATED` / `MANUAL` |
| `created_at`, `updated_at` | DateTime(tz) | auto via `func.now()` |

Relation : `trip: Mapped["Trip"]` avec `back_populates="accommodations"`.

### Permissions et masquage

- **Owner / Editor** : CRUD complet, search hotels, suggestions IA.
- **Viewer** : lecture seule des hebergements, prix / devise / reference masques cote serveur.
- **Trip COMPLETED** : toute mutation refusee avec `TRIP_COMPLETED` (403).

---

## Cote Mobile

### Page autonome (`bagtrip/lib/accommodations/`)

`AccommodationsPage` cree un `BlocProvider<AccommodationBloc>` et dispatch `LoadAccommodations(tripId)`. Cette page existe principalement pour les contextes hors trip-detail (debug, deep-link). Dans le flow nominal, le panel hotel du trip-detail est utilise.

`AccommodationBloc` (`accommodation_bloc.dart`) consomme `AccommodationRepository` (interface `bagtrip/lib/repositories/accommodation_repository.dart`). Tous les handlers respectent le pattern `Result<T>` + `switch` sur `Success` / `Failure`.

| Event | Action |
|-------|--------|
| `LoadAccommodations` | Charge la liste, emit `AccommodationLoading` puis `AccommodationsLoaded` |
| `CreateAccommodation` | POST + ajout optimiste dans la liste courante |
| `UpdateAccommodation` | PATCH + remplacement dans la liste |
| `DeleteAccommodation` | DELETE + retrait de la liste |
| `SuggestAccommodations` | POST `/suggest`, emit `AccommodationSuggestionsLoaded` ou `AccommodationQuotaExceeded` si `QuotaExceededError` |
| `SearchHotels` | GET `/by-city`, emit `HotelSearchLoaded` |
| `SearchHotelOffers` | GET `/offers` pour les hotelIds selectionnes |
| `ClearHotelSearch` | Reset vers `AccommodationInitial` |

### Panel trip-detail (`bagtrip/lib/trip_detail/view/panels/hotel_panel.dart`)

`HotelPanel` est le canal principal de la feature. Il consomme les `accommodations` denormalisees du `TripDetailBloc` et dispatch les events `*FromDetail` (CreateAccommodationFromDetail, UpdateAccommodationFromDetail, DeleteAccommodationFromDetail, ReplaceAccommodationFromDetail, ValidateAccommodationFromDetail). Le panel applique les 4 briques standard SMP-324 :

- **`PanelFab`** : ajout rapide (Android FAB extended, iOS bouton compact).
- **`QuickPreviewSheet`** : tap sur une carte ouvre l'apercu avec `validateAction` (si SUGGESTED + canEdit), `primaryAction` (Replace via Amadeus), `destructiveAction` (delete).
- **`ItemStatusChip`** : halo positionne top-right sur les cartes SUGGESTED (`ValidationStatus.suggested`). Les VALIDATED et MANUAL restent epurees.
- **`ItemFormScaffold`** + `showItemFormSheet` : chrome standardise du `ManualAccommodationForm` (add / edit).

**Skipped tracking** : si `trip.accommodationsTracking == TrackingStatus.skipped`, le panel affiche `SkippedPanelState` avec CTA `panelResumeAccommodationsCta`. L'utilisateur peut aussi skipper depuis l'empty state ou via le bouton sous la liste.

**Sorting** : `_sorted` ordonne par `checkIn` croissant (les sans-date fallback `DateTime(3000)` en queue).

**Carte `_HotelCard`** : header degrade `reviewHeroDark` -> `primaryDark` avec icone `hotel_rounded`, puis nom (DM Serif Display), adresse en uppercase tracking, et `HotelStatsGrid` 4 entrees : check-in, check-out, nights (`checkIn.nightsUntil(checkOut)` clampe 1-365), prix/nuit formate via `formatPrice()`.

### Calcul des nuits (`DateTimeExt.nightsUntil`)

`bagtrip/lib/core/extensions/datetime_ext.dart` definit l'extension partagee. Avant cette extension, chaque widget recopiait `checkOut.difference(checkIn).inDays` avec ses propres garde-fous : duplication dans 5+ cards et off-by-one frequent (notamment quand l'utilisateur saisit un check-in/check-out le meme jour pour un night-trip). La regle :

```dart
int nightsUntil(DateTime checkOut) {
  final nights = checkOut.difference(this).inDays;
  return nights < 1 ? 1 : nights;
}
```

Un check-in/check-out le meme jour compte 1 nuit pour les calculs de prix et les recap. Le backend applique la meme logique via `AccommodationsService._calc_nights` (verites coherentes client / serveur). L'extension est utilisee dans `HotelPanel` (carte + preview), `HotelStatsGrid`, et tout widget qui affiche la duree d'un sejour. Les widgets qui calculent manuellement avec `difference().inDays` sont consideres comme une regression et doivent etre migres a chaque revue de code.

### Flow manual add / edit

Le `ManualAccommodationForm` (widget) collecte nom, adresse, dates (clampees aux bornes du trip via `tripStartDate` / `tripEndDate`), prix/nuit, devise, reference et notes. A la sauvegarde, le panel dispatch `CreateAccommodationFromDetail` ou `UpdateAccommodationFromDetail` au `TripDetailBloc`. Mutation optimiste cote bloc, rollback sur `Failure` via `loggedFailure()`.

### Flow Validate (SUGGESTED -> VALIDATED)

Une suggestion IA arrive avec `validationStatus = SUGGESTED`. Tap sur la carte ouvre le `QuickPreviewSheet` avec un CTA primaire `Validate`. Comme l'hotel n'a pas de branche de booking BagTrip (Amadeus search-only), Validate ouvre `_showExternalBookingRefSheet` : une sheet qui collecte la reference de reservation externe (`booking_reference`), puis dispatch dans l'ordre `UpdateAccommodationFromDetail({bookingReference})` suivi de `ValidateAccommodationFromDetail`. Le second event utilise l'extension `AccommodationRepository.validate` (`lib/repositories/validation_extensions.dart`) qui PATCH `{validationStatus: VALIDATED}`.

### Flow Replace (search-and-replace Amadeus)

`_showReplaceSheet` ouvre un `ReplaceSearchSheet` (sheet plein-ecran 95%, tap-outside dismiss desactive) avec un `HotelSearchSheet` prefille du `trip.destinationIata` et des dates du trip. L'utilisateur cherche, selectionne un hotel, puis un `ManualAccommodationForm` s'ouvre prefille du nom et de l'adresse Amadeus (flag `isEstimatedPrice: true`). La sauvegarde dispatch `ReplaceAccommodationFromDetail(oldAccommodationId, newAccommodationData)` : le bloc handler est atomique (DELETE+CREATE avec rollback en cas d'echec partiel).

### Recherche hotel (deux etapes)

`HotelSearchSheet` enchaine deux events Amadeus :

1. `SearchHotels(cityCode, checkIn, checkOut, adults)` : appelle `/v1/travel/hotels/by-city`, recupere la liste (nom, hotelId, address, geoCode, chainCode, iataCode).
2. `SearchHotelOffers(hotelIds, checkIn, checkOut)` : pour les hotels selectionnes (max 50 IDs concatenes virgule), appelle `/v1/travel/hotels/offers` et recupere les offres avec prix (base, total, currency, room, guests).

`AccommodationBloc` re-emit `HotelSearchLoading` puis `HotelSearchLoaded` (`hotels: List<Map<String, dynamic>>`). Le typage `Map<String, dynamic>` reflete le contrat brut Amadeus passe sans transformation, par choix volontaire : les schemas Amadeus evoluent souvent et le typage Freezed cote mobile ajouterait du bruit pour un usage purement lecture. Cote backend, les schemas Pydantic `HotelListSearchResponse` / `HotelOffersSearchResponse` font office de contrat de surface mais leur contenu est `model_dump()` du resultat Amadeus, pas une re-modelisation.

### Repository (`bagtrip/lib/repositories/accommodation_repository.dart`)

Interface contractuelle, implementee dans `lib/service/accommodation_repository_impl.dart` (nommage historique du monorepo, l'implementation vit cote service). Toutes les methodes retournent `Future<Result<T>>` : pas de throw, pas de cast. L'implementation passe par `ApiClient` (Dio singleton avec JWT auto-injection et single-guard 401 refresh) et mappe les `DioException` en `AppError` via le handler centralise. Les erreurs de quota IA (`429` avec code `QUOTA_EXCEEDED`) sont mappees en `QuotaExceededError`, ce qui permet au bloc de pivoter vers l'etat `AccommodationQuotaExceeded` au lieu d'un simple `AccommodationError`. Le bloc se contente alors d'afficher la paywall premium via le composant partage `QuotaExceededSheet`.

L'extension `AccommodationRepository.validate(...)` (`lib/repositories/validation_extensions.dart`) factorise le PATCH `{validationStatus: VALIDATED}` partage avec les autres domaines (activity, transport, budget). Le handler bloc utilise toujours l'extension, jamais `updateAccommodation({validationStatus: ...})` direct, pour garder le payload uniforme et tracker la mutation de statut sans bruit.

---

## Flux

**Manual add** : panel `+` -> `ManualAccommodationForm` dans `ItemFormScaffold` -> `CreateAccommodationFromDetail` -> POST `/accommodations` -> service cree l'hebergement + le `BudgetItem` lie -> trip-detail recalcule `completionResult`.

**Suggestion IA -> Validate** : trip-detail dispatch `SuggestAccommodationsFromDetail` -> POST `/accommodations/suggest` -> liste affichee avec `ItemStatusChip` SUGGESTED -> tap -> `QuickPreviewSheet` -> Validate -> sheet booking_reference -> PATCH `{bookingReference}` puis PATCH `{validationStatus: VALIDATED}` -> chip disparait.

**Replace via Amadeus** : tap sur carte SUGGESTED -> `QuickPreviewSheet` -> Replace -> `ReplaceSearchSheet` + `HotelSearchSheet` (prefille IATA + dates) -> selection hotel -> `ManualAccommodationForm` prefille -> `ReplaceAccommodationFromDetail` -> DELETE ancienne + CREATE nouvelle, atomique.

**Sync budget** : toute mutation prix declenche la creation / update / suppression du `BudgetItem` lie cote service. Le panel budget reflete immediatement le total sans aller-retour supplementaire car le `TripDetailBloc` recharge le trip complet (activities + flights + accommodations + budget + shares) apres chaque mutation et recompute `completionResult` sur le snapshot global.

**Trip COMPLETED** : une fois le voyage marque comme termine, toute tentative de mutation hebergement renvoie 403 `TRIP_COMPLETED`. Cote mobile, le panel affiche les cartes en lecture seule (`canEdit=false`) : pas de FAB, pas de swipe, pas de Replace.

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Auto-fill prefill depuis offres Amadeus | Le Replace flow prefill nom + adresse, mais pas le prix recupere depuis `/offers`. Le `pricePerNight` reste a saisir manuellement. | P2 |
| Photos hotels | Les reponses Amadeus n'embarquent pas de photos. Pas de fallback Unsplash sur les hebergements. | P2 |
| Carte map | Pas de vue cartographique des hebergements (le panel reste en liste verticale). | P3 |
| Test couverture hotel search | `accommodation_bloc_test.dart` couvre le CRUD mais les events `SearchHotels` / `SearchHotelOffers` / `ClearHotelSearch` sont peu couverts. Pas de widget test dedie pour `HotelSearchSheet`. | P2 |
| Localisation FR du prompt `accommodation_suggest` | Le template Jinja2 FR fallback sur EN tant que la traduction n'est pas ecrite (cohabite avec les autres templates non-traduits du sprint LLM). | P3 |
| Hotel sentiments | `AmadeusService.search_hotel_sentiments` est cable cote backend mais aucun endpoint REST ni consommateur cote mobile ne l'expose. | P3 |
| Notification check-in J-1 | Pas de scheduler pour rappeler le check-in la veille (les notifications activites existent, pas celles d'hebergement). | P2 |
| Hotel offers cache Redis | Les appels `/v1/travel/hotels/offers` ne sont pas caches : chaque ouverture du `HotelSearchSheet` re-tape Amadeus, ce qui consomme du quota et ralentit l'UX. | P2 |
