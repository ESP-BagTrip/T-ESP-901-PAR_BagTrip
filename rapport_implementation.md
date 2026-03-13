# Rapport d'Implémentation — Spécifications V4

## 0. Synthèse de l'Écart

### Statuts Trip

| Spec V4 | Code actuel | Action |
|---|---|---|
| `DRAFT` | `draft` | RENOMMER |
| `PLANNED` | `planning` | RENOMMER |
| `ONGOING` | `active` | RENOMMER |
| `COMPLETED` | `completed` | Uniformiser casse |
| *(n'existe pas)* | `archived` | **SUPPRIMER** |

### Entités — Matrice de couverture

| Entité Spec | Existe ? | Action |
|---|---|---|
| **Trip** | Oui, partiel — manque `budget_total`, `origin`, statuts non conformes | **UPDATE** |
| **Activity** | Non | **CRÉER** |
| **Flight** | Oui (FlightSearch/Offer/Order) — fonctionnel, manque auto BudgetItem | **UPDATE** |
| **Accommodation** | Non (entité simple manuelle) | **CRÉER** |
| **BudgetItem** | Non | **CRÉER** |
| **BaggageItem** | Non | **CRÉER** |
| **TripShare** | Non | **CRÉER** |
| **Feedback** | Non | **CRÉER** |
| **HotelSearch/Offer/Booking** | Oui — **hors scope V4** | **SUPPRIMER** |
| **Conversation/Message/Context** | Oui — inutile, remplacé par prompts système unitaires | **SUPPRIMER** |
| **BookingIntent** | Oui — orchestre paiement vol, compatible spec | **GARDER** |
| **TravelerProfile** | Oui — onboarding/préférences, utile pour IA | **GARDER** |
| **TripTraveler** | Oui — nécessaire pour Amadeus booking | **GARDER** (interne) |

---

## 1. Éléments à Supprimer

| Élément | Raison | Scope suppression |
|---|---|---|
| Statut `archived` | Hors spec V4 | Enum + migration + service |
| Transition `planning→draft` | Spec interdit les retours | `VALID_TRANSITIONS` |
| Transition `completed→archived` | `archived` n'existe pas | `VALID_TRANSITIONS` |
| **HotelSearch / HotelOffer / HotelBooking** | Réservation hébergement = hors scope V4 (§6) | Models, routes, services, migrations, tests |
| Routes `/v1/trips/{id}/hotels/*` | Idem | Router |
| **Conversation / Message / Context** | Remplacé par prompts système unitaires + input unique | Models, routes, services, migrations |
| Routes `/v1/conversations/*`, `/v1/trips/{id}/conversations/*` | Idem | Router |
| `ConversationService`, `MessageService`, `ContextService` | Idem | Services |
| Agent LangGraph (graph + state machine conversation) | Remplacé par appels LLM directs avec system prompt dédié | `api/src/agent/` — réécrire en appels simples |
| Migrations custom (`api/src/migrations/`) | Remplacé par Alembic exclusivement | Supprimer le dossier, retirer du lifespan startup |

---

## 2. Prérequis Fondamentaux (Phase 0 — Socle Transverse)

### P1 — Migration complète vers Alembic
**Priorité : CRITIQUE — Bloque toute création d'entité**

- Supprimer `api/src/migrations/` (migrations custom au startup)
- S'assurer que `api/alembic/` est la seule source de vérité
- Créer une migration initiale Alembic qui reflète l'état actuel de la base
- Toute modification de schéma passe par `alembic revision` (manuel, pas d'autogenerate)

**Scope :** `api/` uniquement

### P2 — Alignement Trip model + machine à états
**Priorité : CRITIQUE — Bloque tout**

- Renommer statuts : `draft→DRAFT`, `planning→PLANNED`, `active→ONGOING`, `completed→COMPLETED`
- Supprimer `archived`
- Ajouter champs : `budget_total` (decimal), `origin` (enum AI/MANUAL)
- Revoir `destination` : IATA → string libre
- Réécrire `VALID_TRANSITIONS` : `DRAFT→PLANNED`, `PLANNED→ONGOING`, `ONGOING→COMPLETED` uniquement
- Migration Alembic

**Scope :** `api/` (model, service, migration) + `bagtrip/` (adapter les modèles Dart et les pages trip)

### P3 — Suppression du code hors scope
**Priorité : HAUTE**

- Supprimer HotelSearch/HotelOffer/HotelBooking (models, routes, services)
- Supprimer Conversation/Message/Context (models, routes, services)
- Supprimer les migrations custom
- Réécrire l'agent IA : remplacer LangGraph par des appels LLM directs (un system prompt par besoin, un input utilisateur, une réponse)
- Migration Alembic pour drop des tables concernées

**Scope :** `api/` + `bagtrip/` (supprimer les pages chat/conversation) + `admin-panel/` (retirer les listings conversations/hotels)

### P4 — Middleware d'autorisation Owner/Viewer
**Priorité : CRITIQUE — Bloque partage, notifications, feedback**

- Dependency FastAPI qui pour chaque route trip-related :
  1. Vérifie que l'utilisateur est owner ou viewer (via future TripShare)
  2. Distingue les droits (write = owner, read-only = viewer)
- Appliquer la matrice §4.3 sur toutes les routes existantes

**Scope :** `api/` uniquement (le filtrage côté Flutter se fait naturellement via les réponses API)

### P5 — Suppression conditionnelle Trip (DRAFT only)
**Priorité : HAUTE**

- Suppression uniquement si `status == DRAFT` (§4.4)
- Cascade : activités, bagages, budget items, hébergements, partages
- Vol `CONFIRMED` avec paiement bloque la suppression

**Scope :** `api/` + `bagtrip/` (griser/masquer le bouton supprimer si non-DRAFT)

### P6 — Job auto-transition PLANNED→ONGOING / ONGOING→COMPLETED
**Priorité : HAUTE — Bloque Phase 3 et 4**

- Job planifié quotidien (00:00 UTC) :
  - `PLANNED → ONGOING` si `start_date <= today`
  - `ONGOING → COMPLETED` si `end_date < today`
- Clôture manuelle d'un trip `ONGOING` par l'owner

**Scope :** `api/` uniquement

---

## 3. Implémentation des Specs

### Couche 1 — Entités CRUD (parallélisable, dépend uniquement de Trip)

Chaque spec = API + Flutter + Admin si pertinent.

| # | Spec | Feature | Scope |
|---|---|---|---|
| **S1** | §2a | **Activity CRUD** — POST/GET/PUT/DELETE `/trips/{id}/activities` | `api/` + `bagtrip/` (page planning jour par jour) + `admin-panel/` (listing) |
| **S2** | §2c | **Accommodation CRUD** (manuel) — POST/GET/PUT/DELETE `/trips/{id}/accommodations` | `api/` + `bagtrip/` (page hébergements) + `admin-panel/` (listing) |
| **S3** | §2d | **BudgetItem CRUD** — POST/GET/PUT/DELETE `/trips/{id}/budget-items` | `api/` + `bagtrip/` (refonte page budget existante) + `admin-panel/` (listing) |
| **S4** | §2e | **BaggageItem CRUD** — POST/GET/PUT/DELETE `/trips/{id}/baggage` | `api/` + `bagtrip/` (page checklist bagages) |
| **S5** | §2.7 | **TripShare CRUD** — POST/GET/DELETE `/trips/{id}/shares` | `api/` + `bagtrip/` (page partage + vue viewer) + `admin-panel/` (listing) |
| **S6** | §2.8 | **Feedback CRUD** — POST/GET `/trips/{id}/feedback` | `api/` + `bagtrip/` (page feedback post-voyage) |

### Couche 2 — Logique Métier (dépend de Couche 1)

| # | Spec | Feature | Dépend de | Scope |
|---|---|---|---|---|
| **S7** | §2c+§2d | **Auto-création BudgetItem → Accommodation** | S2 + S3 | `api/` |
| **S8** | §2b+§2d | **Auto-création BudgetItem → Flight** | S3 + FlightOrder | `api/` |
| **S9** | §2d | **Alertes budget (80% + dépassement)** | S3 | `api/` + `bagtrip/` (affichage alerte visuelle) |
| **S10** | §2f | **Filtrage Viewer** (masquer prix, bloquer écriture) | S5 + P4 | `api/` + `bagtrip/` (UI conditionnelle owner/viewer) |
| **S11** | §2g | **Transition DRAFT→PLANNED** (validation destination+dates) | P2 | `api/` + `bagtrip/` (bouton "marquer prêt") |
| **S12** | §4.6 | **Blocage modif trip COMPLETED** (read-only total) | P2 | `api/` + `bagtrip/` (UI read-only) |

### Couche 3 — IA (appels LLM directs, pas de conversation)

Architecture : un service `LLMService` avec des méthodes dédiées, chacune avec son system prompt.

| # | Spec | Feature | Dépend de | Scope |
|---|---|---|---|---|
| **S13** | Phase 1 | **Inspiration IA** — questionnaire (5 champs) → appel LLM → suggestion (destination, durée, budget, 3+ activités) → créer Trip DRAFT | P2 | `api/` + `bagtrip/` (refonte flow AI existant) |
| **S14** | §2a | **IA suggestions activités** — input: destination+date → output: liste d'activités suggérées | S1 | `api/` + `bagtrip/` (bouton "suggérer" sur page planning) |
| **S15** | §2e | **IA suggestions bagages** — input: destination+durée → output: checklist de base | S4 | `api/` + `bagtrip/` (bouton "suggérer" sur page bagages) |
| **S16** | Phase 4 | **IA post-voyage** — input: feedbacks historiques → output: suggestion nouveau voyage | S6 | `api/` + `bagtrip/` (page post-feedback) |

### Couche 4 — Notifications

| # | Spec | Feature | Dépend de | Scope |
|---|---|---|---|---|
| **S17** | Phase 3 | **Système de notifications (7 types)** | P6, S1, S5, Flight | `api/` (scheduler + push) + `bagtrip/` (Firebase FCM + affichage) |

Les 7 notifications :
1. J-1 avant départ (rappel + statut bagages) → Owner + Viewers
2. H-4 avant vol (alerte + lien billet) → Owner + Viewers
3. H-1 avant vol (rappel imminent) → Owner + Viewers
4. Résumé matin (activités du jour) → Owner + Viewers
5. H-1 avant activité → Owner + Viewers
6. Alerte budget (80% / dépassement) → **Owner uniquement**
7. Fin de voyage (invitation feedback) → Owner + Viewers

### Couche 5 — Segmentation Free/Premium

| # | Spec | Feature | Scope |
|---|---|---|---|
| **S18** | §5 | **Quotas Free/Premium** | `api/` + `bagtrip/` (UI paywall/upgrade) + `admin-panel/` (gestion plans) |

- Génération IA : 3/mois (Free) vs illimité (Premium)
- Viewers/trip : 2 (Free) vs 10 (Premium)
- Notifications offline : Premium only
- Suggestions post-voyage : Premium only

---

## 4. Récapitulatif — Ordre Linéaire Final

```
PHASE 0 — SOCLE TRANSVERSE
  P1  Migration complète vers Alembic           [api]
  P2  Alignement Trip model + machine à états   [api + bagtrip]
  P3  Suppression code hors scope               [api + bagtrip + admin-panel]
       ├─ HotelSearch/Offer/Booking
       ├─ Conversation/Message/Context
       ├─ Migrations custom
       └─ Réécriture agent IA → appels directs
  P4  Middleware autorisation Owner/Viewer       [api]
  P5  Suppression conditionnelle DRAFT only      [api + bagtrip]
  P6  Job auto-transition statuts               [api]

PHASE 1 — ENTITÉS CRUD (parallélisable)
  S1  Activity                                  [api + bagtrip + admin]
  S2  Accommodation                             [api + bagtrip + admin]
  S3  BudgetItem                                [api + bagtrip + admin]
  S4  BaggageItem                               [api + bagtrip]
  S5  TripShare                                 [api + bagtrip + admin]
  S6  Feedback                                  [api + bagtrip]

PHASE 2 — LOGIQUE MÉTIER
  S7  Auto BudgetItem ← Accommodation           [api]
  S8  Auto BudgetItem ← Flight                  [api]
  S9  Alertes budget                            [api + bagtrip]
  S10 Filtrage Viewer                           [api + bagtrip]
  S11 Transition DRAFT→PLANNED                  [api + bagtrip]
  S12 Blocage modif COMPLETED                   [api + bagtrip]

PHASE 3 — IA (appels LLM directs)
  S13 Inspiration IA                            [api + bagtrip]
  S14 IA suggestions activités                  [api + bagtrip]
  S15 IA suggestions bagages                    [api + bagtrip]
  S16 IA suggestions post-voyage                [api + bagtrip]

PHASE 4 — NOTIFICATIONS
  S17 Notifications (7 types)                   [api + bagtrip]

PHASE 5 — COMMERCIAL
  S18 Segmentation Free/Premium                 [api + bagtrip + admin]
```

**Total : 6 prérequis + 18 specs = 24 items de travail.**
