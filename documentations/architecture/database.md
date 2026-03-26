# Base de donnees -- Schema, Migrations, Models

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

BagTrip utilise PostgreSQL 15 comme base de donnees, avec SQLAlchemy 2.0 (pattern `declarative_base`) comme ORM et Alembic pour les migrations. Le driver est `psycopg2-binary`. La gestion des schemas est entierement faite par les migrations Alembic -- aucun `Base.metadata.create_all()` n'est appele au demarrage.

## Configuration SQLAlchemy

**Fichier** : `api/src/config/database.py`

- **Engine** : `create_engine(database_url, pool_pre_ping=True, echo=False)`
- **Session** : `sessionmaker(autocommit=False, autoflush=False)`
- **URL cleanup** : `clean_database_url()` retire le parametre `?schema=` (heritage Prisma) avant de passer l'URL a psycopg2
- **Dependency injection** : `get_db()` est un generateur FastAPI qui yield une session et la ferme dans le finally
- **Health check** : `check_database_connection()` execute `SELECT 1` au demarrage de l'app

**Fichier** : `api/src/config/env.py`

- `DATABASE_URL` par defaut : `postgresql://postgres:postgres@localhost:5432/postgres`
- En Docker, surcharge : `postgresql://postgres:postgres@db:5432/bagtrip` (host `db` = service Docker)

## Schema de la base de donnees

### Diagramme des tables

```
users (1) ----< trips (1) ----< trip_travelers
  |                |
  |                |----< activities
  |                |----< accommodations
  |                |----< baggage_items
  |                |----< budget_items
  |                |----< manual_flights
  |                |----< feedbacks (unique: trip_id + user_id)
  |                |----< trip_shares (unique: trip_id + user_id)
  |                |----< flight_searches (1) ----< flight_offers (1) ----< flight_orders
  |                |----< booking_intents (1) ----< stripe_events
  |                |                     (1) ----  flight_orders (1:1 via unique FK)
  |                |----< notifications
  |
  |----< refresh_tokens
  |----< device_tokens
  |---- traveler_profiles (1:1 via unique FK)
  |----< booking_intents
  |----< notifications
  |----< feedbacks
  |----< trip_shares

amadeus_api_logs ---- trips (FK nullable)
                 ---- booking_intents (FK nullable)

bookings (DEPRECATED) ---- users

stripe_events ---- booking_intents (FK nullable)
```

### Tables actives (20 tables)

#### `users`
Utilisateurs de l'application.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK, default uuid4 |
| email | String | UNIQUE, NOT NULL, INDEX |
| password_hash | String | NOT NULL |
| full_name | String | nullable |
| phone | String | nullable |
| stripe_customer_id | String | nullable, INDEX |
| plan | String(10) | NOT NULL, default "FREE" |
| stripe_subscription_id | String | nullable, INDEX |
| plan_expires_at | DateTime(tz) | nullable |
| ai_generations_count | Integer | NOT NULL, default 0 |
| ai_generations_reset_at | DateTime(tz) | nullable |
| created_at | DateTime(tz) | NOT NULL, server_default now() |
| updated_at | DateTime(tz) | NOT NULL, server_default now(), onupdate |

#### `trips`
Voyages crees par les utilisateurs.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| user_id | UUID | FK users.id, NOT NULL, INDEX |
| title | String | nullable |
| origin_iata | String(3) | nullable |
| destination_iata | String(3) | nullable |
| start_date | Date | nullable |
| end_date | Date | nullable |
| status | String | NOT NULL, default "DRAFT" |
| description | String | nullable |
| budget_total | Numeric(12,2) | nullable |
| origin | String | nullable, default "MANUAL" |
| cover_image_url | String | nullable |
| destination_name | String | nullable |
| nb_travelers | Integer | nullable, default 1 |
| date_mode | String | NOT NULL, default "EXACT" |
| archived_at | DateTime(tz) | nullable |
| created_at / updated_at | DateTime(tz) | standard |

**Statuts** (enum `TripStatus`) : `DRAFT` -> `PLANNED` -> `ONGOING` -> `COMPLETED`

**Modes de date** (enum `DateMode`) : `EXACT`, `MONTH`, `FLEXIBLE`

**Relationships** : travelers, accommodations, baggage_items, flight_searches, booking_intents, shares, activities, budget_items, feedbacks, manual_flights

#### `activities`
Activites planifiees dans un trip.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| title | String | NOT NULL |
| description | String | nullable |
| date | Date | NOT NULL |
| start_time | Time | nullable |
| end_time | Time | nullable |
| location | String | nullable |
| category | String | NOT NULL, default "OTHER" |
| estimated_cost | Numeric(12,2) | nullable |
| is_booked | Boolean | NOT NULL, default false |
| validation_status | String | NOT NULL, default "MANUAL" |
| created_at / updated_at | DateTime(tz) | standard |

**Categories** (enum `ActivityCategory`) : CULTURE, NATURE, FOOD, SPORT, SHOPPING, NIGHTLIFE, RELAXATION, OTHER

**Validation status** (enum `ValidationStatus`) : SUGGESTED, VALIDATED, MANUAL

#### `accommodations`
Hebergements d'un trip.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| name | String | NOT NULL |
| address | String | nullable |
| check_in | DateTime(tz) | nullable |
| check_out | DateTime(tz) | nullable |
| price_per_night | Numeric(12,2) | nullable |
| currency | String(3) | nullable, default "EUR" |
| booking_reference | String | nullable |
| notes | String | nullable |
| created_at / updated_at | DateTime(tz) | standard |

#### `baggage_items`
Elements de bagages a preparer.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| name | String | NOT NULL |
| quantity | Integer | NOT NULL, default 1 |
| is_packed | Boolean | NOT NULL, default false |
| category | String | NOT NULL, default "OTHER" |
| notes | String | nullable |
| created_at / updated_at | DateTime(tz) | standard |

**Categories** (enum `BaggageCategory`) : DOCUMENTS, CLOTHING, ELECTRONICS, TOILETRIES, HEALTH, ACCESSORIES, OTHER

#### `budget_items`
Elements de budget d'un trip (depenses planifiees et reelles).

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| label | String | NOT NULL |
| amount | Numeric(12,2) | NOT NULL |
| category | String | NOT NULL, default "OTHER" |
| date | Date | nullable |
| is_planned | Boolean | NOT NULL, default true |
| source_type | String | nullable ("accommodation", "flight_order") |
| source_id | UUID | nullable |
| created_at / updated_at | DateTime(tz) | standard |

**Index composite** : `ix_budget_items_source` sur (source_type, source_id)

**Categories** (enum `BudgetCategory`) : FLIGHT, ACCOMMODATION, FOOD, ACTIVITY, TRANSPORT, OTHER

#### `trip_travelers`
Voyageurs associes a un trip (informations Amadeus).

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| amadeus_traveler_ref | String | nullable |
| traveler_type | String | NOT NULL (ADULT, CHILD, etc.) |
| first_name | String | NOT NULL |
| last_name | String | NOT NULL |
| date_of_birth | Date | nullable |
| gender | String | nullable |
| documents | JSON | nullable |
| contacts | JSON | nullable |
| raw | JSON | nullable (payload Amadeus complet) |
| created_at / updated_at | DateTime(tz) | standard |

#### `trip_shares`
Partage d'un trip avec un autre utilisateur.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| user_id | UUID | FK users.id, NOT NULL, INDEX |
| role | String | NOT NULL, default "VIEWER" |
| invited_at | DateTime(tz) | NOT NULL, server_default now() |

**Contrainte unique** : `uq_trip_shares_trip_user` sur (trip_id, user_id)

**Roles** (enum `ShareRole`) : seul `VIEWER` pour l'instant

#### `flight_searches`
Recherches de vols via Amadeus.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| origin_iata / destination_iata | String(3) | NOT NULL |
| departure_date | Date | NOT NULL |
| return_date | Date | nullable |
| adults | Integer | NOT NULL |
| children / infants | Integer | nullable |
| travel_class | String | nullable |
| non_stop | Boolean | nullable |
| currency | String(3) | nullable |
| amadeus_request | JSON | NOT NULL |
| amadeus_response | JSON | nullable |
| amadeus_response_received_at | DateTime(tz) | nullable |
| created_at | DateTime(tz) | standard |

#### `flight_offers`
Offres de vols retournees par Amadeus.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| flight_search_id | UUID | FK flight_searches.id, NOT NULL, INDEX |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| amadeus_offer_id | String | nullable |
| source | String | nullable |
| validating_airline_codes | String | nullable |
| last_ticketing_datetime | DateTime(tz) | nullable |
| currency | String(3) | nullable |
| grand_total / base_total | Numeric(10,2) | nullable |
| offer_json | JSON | NOT NULL (payload Amadeus complet) |
| priced_offer_json | JSON | nullable (si reprice) |
| created_at | DateTime(tz) | standard |

#### `flight_orders`
Commandes de vols confirmees.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| flight_offer_id | UUID | FK flight_offers.id, NOT NULL |
| booking_intent_id | UUID | FK booking_intents.id, nullable, UNIQUE |
| amadeus_flight_order_id | String | nullable, UNIQUE |
| status | String | nullable |
| booking_reference | String | nullable |
| payment_id | String | nullable |
| ticket_url | String | nullable |
| amadeus_create_order_request | JSON | NOT NULL |
| amadeus_create_order_response | JSON | nullable |
| created_at / updated_at | DateTime(tz) | standard |

#### `booking_intents`
Orchestration du flux de reservation (Stripe + Amadeus).

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| user_id | UUID | FK users.id, NOT NULL, INDEX |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| type | String | NOT NULL ("flight") |
| status | String | NOT NULL, INDEX |
| amount | Numeric(10,2) | NOT NULL |
| currency | String(3) | NOT NULL |
| selected_offer_type | String | nullable ("flight_offer") |
| selected_offer_id | UUID | nullable |
| selected_offer_payload_hash | String | nullable |
| stripe_payment_intent_id | String | nullable |
| stripe_charge_id | String | nullable |
| amadeus_order_id | String | nullable |
| last_error | JSON | nullable |
| raw | JSON | nullable (metadata, idempotency keys) |
| created_at / updated_at | DateTime(tz) | standard |

**Statuts** (enum `BookingIntentStatus`) : INIT -> AUTHORIZED -> BOOKING_PENDING -> BOOKED -> CAPTURED | FAILED | CANCELLED | PAYMENT_CAPTURE_FAILED

#### `manual_flights`
Vols saisis manuellement (hors Amadeus).

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| flight_number | String | NOT NULL |
| airline | String | nullable |
| departure_airport / arrival_airport | String | nullable |
| departure_date / arrival_date | DateTime(tz) | nullable |
| price | Numeric(12,2) | nullable |
| currency | String | nullable, default "EUR" |
| notes | String | nullable |
| flight_type | String | NOT NULL, default "MAIN" |
| created_at / updated_at | DateTime(tz) | standard |

**Types de vol** (enum `FlightType`) : MAIN, INTERNAL

#### `feedbacks`
Avis utilisateur sur un trip termine.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| trip_id | UUID | FK trips.id, NOT NULL, INDEX |
| user_id | UUID | FK users.id, NOT NULL, INDEX |
| overall_rating | Integer | NOT NULL |
| highlights | Text | nullable |
| lowlights | Text | nullable |
| would_recommend | Boolean | NOT NULL |
| ai_experience_rating | Integer | nullable |
| created_at | DateTime(tz) | standard |

**Contrainte unique** : `uq_feedbacks_trip_user` sur (trip_id, user_id)

#### `notifications`
Notifications push envoyees aux utilisateurs.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| user_id | UUID | FK users.id, NOT NULL, INDEX |
| trip_id | UUID | FK trips.id, nullable, INDEX |
| type | String | NOT NULL |
| title | String | NOT NULL |
| body | String | NOT NULL |
| data | JSON | nullable |
| is_read | Boolean | NOT NULL, default false |
| sent_at | DateTime(tz) | nullable |
| created_at | DateTime(tz) | standard |

**Types** (enum `NotificationType`) : DEPARTURE_REMINDER, FLIGHT_H4, FLIGHT_H1, MORNING_SUMMARY, ACTIVITY_H1, TRIP_STARTED, TRIP_ENDED, BUDGET_ALERT, TRIP_SHARED, ADMIN

#### `device_tokens`
Tokens FCM pour les push notifications.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| user_id | UUID | FK users.id, NOT NULL, INDEX |
| fcm_token | String | NOT NULL, UNIQUE |
| platform | String | nullable |
| created_at / updated_at | DateTime(tz) | standard |

#### `refresh_tokens`
Tokens de rafraichissement JWT (rotation server-side).

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| user_id | UUID | FK users.id, NOT NULL, INDEX |
| token | String | UNIQUE, NOT NULL, INDEX |
| expires_at | DateTime(tz) | NOT NULL |
| revoked | Boolean | NOT NULL, default false |
| created_at | DateTime(tz) | standard |

#### `traveler_profiles`
Profil voyageur avec preferences de personnalisation (onboarding).

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| user_id | UUID | FK users.id, UNIQUE, NOT NULL, INDEX |
| travel_types | JSON | nullable |
| travel_style | String | nullable |
| budget | String | nullable |
| companions | String | nullable |
| medical_constraints | String | nullable |
| is_completed | Boolean | NOT NULL, default false |
| created_at / updated_at | DateTime(tz) | standard |

#### `stripe_events`
Evenements Stripe recus via webhook.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| stripe_event_id | String | UNIQUE, NOT NULL |
| type | String | NOT NULL |
| livemode | Boolean | nullable |
| payload | JSON | NOT NULL |
| received_at | DateTime(tz) | standard |
| booking_intent_id | UUID | FK booking_intents.id, nullable |
| processed_at | DateTime(tz) | nullable |
| processing_error | JSON | nullable |

#### `amadeus_api_logs`
Logs des appels API Amadeus (audit trail).

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| trip_id | UUID | FK trips.id, nullable, INDEX |
| booking_intent_id | UUID | FK booking_intents.id, nullable, INDEX |
| api_name | String | NOT NULL, INDEX |
| http_method | String | NOT NULL |
| path | String | NOT NULL |
| request_headers / request_body | JSON | nullable |
| response_status | Integer | nullable |
| response_headers / response_body | JSON | nullable |
| duration_ms | Integer | nullable |
| created_at | DateTime(tz) | standard |

#### `bookings` (DEPRECATED)
Ancienne table de reservations. Remplacee par le pattern `booking_intents` + `flight_orders`.

| Colonne | Type | Contraintes |
|---------|------|------------|
| id | UUID | PK |
| user_id | UUID | FK users.id, NOT NULL |
| amadeus_order_id | String | NOT NULL |
| flight_offers | JSON | NOT NULL |
| status | String | NOT NULL, default "CONFIRMED" |
| price_total | Float | NOT NULL |
| currency | String | NOT NULL |
| createdAt / updatedAt | DateTime(tz) | NOTE: camelCase column names (heritage Prisma) |

## Enums (`api/src/enums.py`)

Tous les enums sont des `StrEnum` centralises dans un fichier unique :

- `TripStatus` : DRAFT, PLANNED, ONGOING, COMPLETED
- `TripOrigin` : AI, MANUAL
- `ActivityCategory` : CULTURE, NATURE, FOOD, SPORT, SHOPPING, NIGHTLIFE, RELAXATION, OTHER
- `BudgetCategory` : FLIGHT, ACCOMMODATION, FOOD, ACTIVITY, TRANSPORT, OTHER
- `BaggageCategory` : DOCUMENTS, CLOTHING, ELECTRONICS, TOILETRIES, HEALTH, ACCESSORIES, OTHER
- `ShareRole` : VIEWER
- `FlightOrderStatus` : CONFIRMED, CANCELLED
- `BookingIntentStatus` : INIT, AUTHORIZED, BOOKING_PENDING, BOOKED, CAPTURED, FAILED, CANCELLED, PAYMENT_CAPTURE_FAILED
- `BookingIntentType` : flight
- `NotificationType` : DEPARTURE_REMINDER, FLIGHT_H4, FLIGHT_H1, MORNING_SUMMARY, ACTIVITY_H1, TRIP_STARTED, TRIP_ENDED, BUDGET_ALERT, TRIP_SHARED, ADMIN
- `ValidationStatus` : SUGGESTED, VALIDATED, MANUAL
- `DateMode` : EXACT, MONTH, FLEXIBLE
- `BudgetPreset` : BACKPACKER, COMFORTABLE, PREMIUM, NO_LIMIT
- `FlightType` : MAIN, INTERNAL

## Migrations Alembic

### Configuration

- **Fichier INI** : `api/alembic.ini` (URL par defaut : `postgresql://localhost/bagtrip`, surchargee par `env.py`)
- **Fichier env** : `api/alembic/env.py` -- importe tous les models via `import src.models`, surcharge l'URL avec `settings.DATABASE_URL`
- **Note importante** : les migrations ne sont PAS auto-generees (pas de PostgreSQL local). Elles sont creees manuellement.

### Historique des migrations (21 revisions)

| Revision | Description |
|----------|-------------|
| `0001` | Initial baseline -- 17 tables (users, trips, trip_travelers, flight_searches, flight_offers, booking_intents, flight_orders, hotel_searches, hotel_offers, hotel_bookings, conversations, messages, contexts, stripe_events, amadeus_api_logs, refresh_tokens, traveler_profiles, bookings) |
| `0002` | Align trip model (ajout budget_total, origin, cover_image_url) |
| `0003` | Add trip_shares |
| `0004` | Drop hotel_searches, hotel_offers, hotel_bookings, conversations, messages, contexts (cleanup legacy) |
| `0005` | Add accommodations and baggage_items |
| `0006` | Create activities |
| `0007` | Create budget_items |
| `0008` | Add feedbacks table |
| `0009` | Add budget_item source tracking (source_type, source_id) |
| `0010` | Add notifications and device_tokens |
| `0011` | Add user plan and quotas (plan, stripe_subscription_id, ai_generations_count, etc.) |
| `0012` | Cleanup data models |
| `0013` | Add flight_order payment and ticket fields (payment_id, ticket_url) |
| `0014` | Create manual_flights |
| `0015` | Add activity validation_status |
| `0016` | Add medical_constraints to traveler_profiles |
| `0017` | Unify activity and baggage categories |
| `0018` | Add notification type TRIP_STARTED |
| `0019` | Add trip date_mode |
| `0020` | Add ai_experience_rating to feedbacks |
| `0021` | Accommodation check_in/check_out to DateTime (was Date) |

### Tables droppees (migration 0004)

Ces tables existaient dans le baseline mais ont ete supprimees :
- `hotel_searches`, `hotel_offers`, `hotel_bookings` -- recherche hoteliere deplacee vers un service externe
- `conversations`, `messages`, `contexts` -- chat IA remplace par le pattern LangGraph agent

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Soft delete non uniforme | La table `trips` a un champ `archived_at` pour le soft delete, mais aucune autre table n'a ce pattern. Les suppressions des sous-entites sont en cascade hard delete (`cascade="all, delete-orphan"`). | P1 |
| Pas d'index sur les FK non-indexees | Certaines FK ne sont pas indexees : `flight_orders.flight_offer_id`, `bookings.user_id`. Les FK indexees sont explicitement marquees `index=True`. | P1 |
| Downgrade migration 0004 impossible | La migration 0004 leve `NotImplementedError` sur downgrade. Les tables dropees (hotel_*, conversations, messages, contexts) ne peuvent pas etre restaurees. | P2 |
| Table `bookings` deprecated | Le model `Booking` et la route sont encore presents dans le code. La table utilise des colonnes camelCase (`createdAt`, `updatedAt`) -- heritage Prisma incompatible avec le pattern snake_case du reste du schema. | P2 |
| Autogenerate Alembic non fonctionnel | Selon MEMORY.md : "No local PostgreSQL running -- migrations must be created manually, not via `--autogenerate`". Cela rend les migrations sujettes a des oublis de schema drift. | P1 |
| Pas de purge des refresh_tokens expires | Les refresh tokens expires ne sont jamais nettoyes automatiquement. Aucun job de purge n'existe dans `api/src/jobs/`. | P2 |
| Pas de purge des amadeus_api_logs | Les logs API Amadeus s'accumulent sans retention. Aucune politique de purge n'existe. | P2 |
