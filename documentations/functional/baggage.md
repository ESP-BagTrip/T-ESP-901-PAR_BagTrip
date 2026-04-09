# Bagages (Checklist IA)

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

La feature Bagages fournit une checklist interactive pour preparer ses affaires avant un voyage. Elle combine gestion manuelle (ajout, suppression, reordonnancement) avec des suggestions IA contextualisees basees sur la destination, la duree du voyage et les activites prevues. Chaque item a un statut "packed" avec une barre de progression visuelle et une celebration a 100%.

---

## Architecture mobile (Flutter)

### BLoC

`BaggageBloc` (`bagtrip/lib/baggage/bloc/baggage_bloc.dart`) gere l'integralite de la feature via `BaggageRepository`.

| Event | Action |
|-------|--------|
| `LoadBaggage` | Charge tous les items du trip, calcule packed/total |
| `TogglePacked` | Bascule l'etat packed d'un item. Detecte la transition vers 100% pour declencher la celebration |
| `DeleteBaggageItem` | Supprime un item |
| `CreateBaggageItem` | Cree un item avec nom, quantite et categorie |
| `SuggestBaggage` | Appelle l'IA pour des suggestions contextualisees. Preserve la liste courante pendant le chargement |
| `AcceptSuggestion` | Accepte une suggestion IA : cree l'item en base puis recharge la liste, retire la suggestion acceptee |
| `DismissSuggestion` | Rejette une suggestion (retrait de la liste locale, pas d'appel API) |
| `UpdateBaggageItem` | Met a jour un item existant (nom, quantite, categorie) via PATCH. Owner only |
| `ReorderBaggageItem` | Reordonne les items non-packed par drag & drop (local uniquement, pas persiste) |

### Etats

| State | Description |
|-------|-------------|
| `BaggageInitial` | Etat initial |
| `BaggageLoading` | Chargement en cours |
| `BaggageLoaded` | Contient : `items`, `packedCount`, `totalCount`, `suggestions` (vide par defaut), `celebrationTriggered` |
| `BaggageSuggestionsLoading` | Chargement IA en cours (preserve items + counts de l'etat precedent) |
| `BaggageQuotaExceeded` | Quota IA depasse |
| `BaggageError` | Erreur avec `AppError` |

### Modeles Freezed

**BaggageItem** (`bagtrip/lib/models/baggage_item.dart`) :
- `id`, `tripId`, `name` (obligatoires)
- `quantity` (int?), `isPacked` (defaut false), `category` (String?), `notes` (String?)
- `createdAt`, `updatedAt`

**SuggestedBaggageItem** (`bagtrip/lib/models/suggested_baggage_item.dart`) :
- `name` (obligatoire)
- `quantity` (defaut 1), `category` (defaut 'Autre'), `reason` (optionnel — justification de l'IA)

### Categories de bagages

Definies dans `api/src/enums.py` sous `BaggageCategory` :

| Valeur | Description |
|--------|-------------|
| `DOCUMENTS` | Passeport, billets, etc. |
| `CLOTHING` | Vetements |
| `ELECTRONICS` | Chargeur, adaptateur, etc. |
| `TOILETRIES` | Produits d'hygiene |
| `HEALTH` | Trousse de secours, medicaments |
| `ACCESSORIES` | Accessoires divers |
| `OTHER` | Autre |

### Widgets

| Widget | Fichier | Role |
|--------|---------|------|
| `BaggagePage` | `baggage/view/baggage_page.dart` | Cree le BlocProvider et fire `LoadBaggage` |
| `BaggageView` | `baggage/view/baggage_view.dart` | UI principale |
| `BaggageProgressHeader` | `baggage/widgets/baggage_progress_header.dart` | Arc de progression circulaire (CustomPaint) + barre lineaire + compteur "X/Y" |
| `BaggageItemTile` | `baggage/widgets/baggage_item_tile.dart` | Ligne d'un item avec checkbox, tap-to-edit, `AdaptiveContextMenu` iOS (edit + delete) |
| `BaggageAddForm` | `baggage/widgets/baggage_add_form.dart` | Formulaire d'ajout (nom, quantite, categorie) |
| `BaggageEditForm` | `baggage/widgets/baggage_edit_form.dart` | Formulaire d'edition d'un item existant (nom, quantite, categorie), pre-rempli |
| `BaggageSuggestionCard` | `baggage/widgets/baggage_suggestion_card.dart` | Carte de suggestion IA avec boutons accepter/rejeter et animation fade-out |
| `BaggageCelebration` | `baggage/widgets/baggage_celebration.dart` | Animation de celebration quand tout est packed |

### Fonctionnalites UX detaillees

**Barre de progression** (`BaggageProgressHeader`) :
- Arc circulaire (`_ProgressArcPainter`) avec ratio packed/total
- Compteur numerique au centre de l'arc
- Barre lineaire en dessous avec `LinearProgressIndicator`
- Couleur : `AppColors.success`

**Suggestions IA** (`BaggageSuggestionCard`) :
- Icone `auto_awesome` (sparkle) dans un cercle primaire
- Nom de l'item + raison de la suggestion en sous-titre
- Bouton accepter (check vert) et rejeter (croix grise)
- Animation d'opacite au fade-out (300ms) avant le callback

**Celebration** :
- Detectee dans `_onTogglePacked` : quand `packed == total` et ce n'etait pas le cas avant
- `celebrationTriggered: true` dans `BaggageLoaded`
- Widget `BaggageCelebration` pour l'animation

**Drag & drop** :
- `ReorderBaggageItem` reordonne uniquement les items non-packed
- Les items packed restent a la fin de la liste
- L'ordre n'est pas persiste cote serveur

---

## Architecture backend (FastAPI)

### Endpoints bagages

- `POST /v1/trips/{tripId}/baggage` — Cree un item. Body : `name` (obligatoire), `quantity?`, `isPacked?`, `category?` (BaggageCategory enum), `notes?`. Owner only. Retourne 201.

- `GET /v1/trips/{tripId}/baggage` — Liste tous les items du trip. Owner + Viewer.

- `PATCH /v1/trips/{tripId}/baggage/{baggageItemId}` — Mise a jour partielle (name, quantity, isPacked, category, notes). Owner only.

- `DELETE /v1/trips/{tripId}/baggage/{baggageItemId}` — Suppression. Owner only. Retourne 204.

- `POST /v1/trips/{tripId}/baggage/suggest` — Suggestions IA. Owner only + verification quota IA (`require_ai_quota`). Appelle `BaggageItemsService.suggest_baggage_items()` puis incremente le compteur IA via `PlanService.increment_ai_generation()`.

### Service IA — Suggestions de bagages

`BaggageItemsService.suggest_baggage_items()` (`api/src/services/baggage_items_service.py`) :

1. Construit un prompt contextualise avec :
   - Destination du trip
   - Duree du voyage (en jours)
   - Activites prevues (jusqu'a 8 titres)
   - Nombre de voyageurs

2. Appelle `LLMService.acall_llm()` avec le prompt systeme `BAGGAGE_PROMPT`

3. Parse la reponse en liste de `{name, quantity, category, reason}`

4. **Deduplication** : filtre les suggestions dont le nom (case-insensitive) existe deja dans les items du trip

5. **Fallback** : si le LLM echoue, retourne une liste par defaut de 6 items essentiels (Passport, Travel adapter, Sunscreen, First aid kit, Phone charger, Change of clothes)

### Schema de reponse suggestions

```
BaggageSuggestionItem :
  name (str), quantity (int, defaut 1), category (str, defaut "OTHER"), reason (str?)

BaggageSuggestionListResponse :
  items: list[BaggageSuggestionItem]
```

### Modele SQLAlchemy

`BaggageItem` (`api/src/models/baggage_item.py`) :
- `id` (UUID, PK)
- `trip_id` (FK vers trips)
- `name` (String, not null)
- `quantity` (Integer), `is_packed` (Boolean), `category` (String)
- `notes` (String)
- `created_at`, `updated_at`

### Permissions

- Owner : CRUD complet + suggestions IA
- Viewer : lecture seule
- Les modifications sont bloquees sur les trips au statut COMPLETED

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Persistence du reordonnancement | L'event `ReorderBaggageItem` reordonne les items localement dans le bloc mais ne persiste pas l'ordre cote API (pas de champ `position`/`order` dans le modele). A la prochaine ouverture, l'ordre est perdu. (`bagtrip/lib/baggage/bloc/baggage_bloc.dart:270-287`) | P2 |
| ~~Edition d'un item existant~~ | ~~Le mobile n'expose pas de formulaire d'edition.~~ ✅ `UpdateBaggageItem` event + `BaggageEditForm` bottom sheet (nom, qte, categorie) + tap-to-edit + `AdaptiveContextMenu` iOS | ~~P1~~ ✅ |
| Partage de checklist entre voyageurs | Les viewers peuvent voir la checklist mais pas contribuer. Pas de notion de "checklist partagee" ou d'assignation d'items a des voyageurs specifiques. | P2 |
| Export/impression de la checklist | Pas de fonctionnalite d'export PDF ou de partage de la checklist. | P2 |
| Tri et filtrage par categorie | L'UI n'offre pas de filtre par categorie (DOCUMENTS, CLOTHING, etc.). Les items sont affiches dans l'ordre non-packed puis packed. | P2 |
| Tests widget BaggageCelebration | Pas de test dedie pour le widget `BaggageCelebration` (`bagtrip/lib/baggage/widgets/baggage_celebration.dart`). | P2 |
