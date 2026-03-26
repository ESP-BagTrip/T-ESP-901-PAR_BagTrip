# Budget

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

La feature Budget permet de suivre les depenses d'un voyage avec un budget total, des postes de depense par categorie, des alertes de depassement et une estimation IA. Le systeme distingue les depenses confirmees (liees a une source ou non-planifiees) des depenses previsionnelles, et inclut les couts des activites validees dans le calcul. Les viewers ont un acces restreint (pourcentage consomme uniquement).

---

## Architecture mobile (Flutter)

### BLoC

`BudgetBloc` (`bagtrip/lib/budget/bloc/budget_bloc.dart`) gere la feature via `BudgetRepository`.

| Event | Action |
|-------|--------|
| `LoadBudget` | Charge en parallele les items ET le summary (via `Future.wait`) |
| `CreateBudgetItem` | Cree un item (ajout optimiste dans la liste) |
| `UpdateBudgetItem` | Met a jour un item existant (remplacement dans la liste) |
| `DeleteBudgetItem` | Supprime un item (retrait de la liste) |
| `EstimateBudget` | Appelle l'IA pour une estimation budgetaire. Preserve items + summary courants pendant le chargement |
| `AcceptBudgetEstimate` | Accepte l'estimation : appelle `acceptBudgetEstimate()` sur le repo avec le montant total, puis recharge le budget |

### Etats

| State | Description |
|-------|-------------|
| `BudgetInitial` | Etat initial |
| `BudgetLoading` | Chargement en cours |
| `BudgetLoaded` | Contient `items` (List<BudgetItem>) + `summary` (BudgetSummary) |
| `BudgetEstimating` | Estimation IA en cours |
| `BudgetEstimated` | Estimation recue : contient `estimation` + `items` + `summary` preserves |
| `BudgetQuotaExceeded` | Quota IA depasse |
| `BudgetError` | Erreur avec `AppError` |

### Modeles Freezed

**BudgetItem** (`bagtrip/lib/models/budget_item.dart`) :
- `id`, `tripId`, `label`, `amount` (obligatoires)
- `category` (enum `BudgetCategory`, defaut `other`)
- `date` (DateTime?), `isPlanned` (bool, defaut true)
- `sourceType`, `sourceId` — lien vers la source (ex: vol, hebergement)
- `createdAt`, `updatedAt`

**BudgetCategory** (enum) :

| Valeur | Usage |
|--------|-------|
| `FLIGHT` | Vols |
| `ACCOMMODATION` | Hebergement |
| `FOOD` | Nourriture |
| `ACTIVITY` | Activites |
| `TRANSPORT` | Transports locaux |
| `OTHER` | Autre |

**BudgetSummary** (`bagtrip/lib/models/budget_item.dart`) :
- `totalBudget` : budget total defini pour le trip
- `totalSpent` : somme des depenses
- `remaining` : totalBudget - totalSpent
- `byCategory` : ventilation par categorie (Map<String, double>)
- `confirmedTotal` : depenses confirmees (source_type non null ou non planifiees)
- `forecastedTotal` : depenses previsionnelles (planifiees sans source)
- `percentConsumed` : pourcentage utilise
- `alertLevel` : "WARNING" (>=80%) ou "DANGER" (>=100%)
- `alertMessage` : message d'alerte localise

**BudgetEstimation** (`bagtrip/lib/models/budget_estimation.dart`) :
- `accommodationPerNight` : estimation logement par nuit
- `mealsPerDayPerPerson` : estimation repas par jour par personne
- `localTransportPerDay` : transports locaux par jour
- `activitiesTotal` : total activites
- `totalMin`, `totalMax` : fourchette basse/haute
- `currency` (defaut EUR)
- `breakdownNotes` : notes explicatives de l'IA

### Widgets

| Widget | Fichier | Role |
|--------|---------|------|
| `BudgetPage` | `budget/view/budget_page.dart` | Cree le BlocProvider et fire `LoadBudget` |
| `BudgetView` | `budget/view/budget_view.dart` | UI principale |
| `BudgetSummaryHeader` | `budget/widgets/budget_summary_header.dart` | Header avec 3 colonnes (total, confirme, prevu) + double barre de progression |
| `BudgetAlertBanner` | `budget/widgets/budget_alert_banner.dart` | Banniere d'alerte WARNING (jaune) ou DANGER (rouge) |
| `BudgetItemCard` | `budget/widgets/budget_item_card.dart` | Carte d'un poste de depense |
| `BudgetItemForm` | `budget/widgets/budget_item_form.dart` | Formulaire de creation/edition |
| `BudgetEstimateSheet` | `budget/widgets/budget_estimate_sheet.dart` | Bottom sheet IA avec shimmer, breakdown et actions |

### Header de budget detaille

Le `BudgetSummaryHeader` affiche :
- Trois colonnes : Budget total (primary, large), Confirme (indicateur barre solide), Prevu (indicateur barre pointillee)
- Double barre de progression empilee :
  - Barre de fond : `AppColors.border`
  - Barre previsionnelle (confirme + prevu, alpha 0.3)
  - Barre confirmee (solide, primary)
- Ratio calcule : `confirmedTotal / totalBudget` et `(confirmed + forecasted) / totalBudget`
- Pour les viewers : affichage du pourcentage consomme uniquement

### Alertes de budget

Le `BudgetAlertBanner` affiche une banniere contextuelle :
- **WARNING** (>= 80%) : icone `warning`, fond jaune, message "{X}% of your budget has been used"
- **DANGER** (>= 100%) : icone `error`, fond rouge, message "Budget exceeded by {X} EUR"

### Estimation IA

Le `BudgetEstimateSheet` est un `DraggableScrollableSheet` (65% -> 90%) qui :
1. Affiche un shimmer pendant le chargement (`BudgetEstimating`)
2. Montre le breakdown avec 4 lignes : hebergement/nuit, repas/jour, transport local/jour, activites total
3. Affiche la fourchette totale (min-max) en bas
4. Deux boutons d'action :
   - "Modifier" : ouvre un dialogue pour ajuster le montant
   - "Accepter" : fire `AcceptBudgetEstimate` avec la moyenne (min+max)/2

---

## Architecture backend (FastAPI)

### Endpoints budget

- `POST /v1/trips/{tripId}/budget-items` — Cree un item. Body : `label`, `amount` (float), `category?` (BudgetCategory enum), `date?`, `isPlanned?`. Owner only. Declenche `NotificationService.check_and_send_budget_alert()` apres creation.

- `GET /v1/trips/{tripId}/budget-items` — Liste les items. **Viewers** : retourne une liste vide (pas d'acces aux details).

- `GET /v1/trips/{tripId}/budget-items/summary` — Summary budgetaire. **Viewers** : recoivent totalBudget, percent_consumed, mais totalSpent=0, remaining=0, by_category vide.

- `GET /v1/trips/{tripId}/budget-items/{itemId}` — Detail d'un item. Interdit aux viewers (403).

- `PUT /v1/trips/{tripId}/budget-items/{itemId}` — Mise a jour complete. Owner only. Declenche l'alerte budget.

- `DELETE /v1/trips/{tripId}/budget-items/{itemId}` — Suppression. Owner only. Declenche l'alerte budget.

### Calcul du summary (`BudgetItemService.get_budget_summary()`)

Le service (`api/src/services/budget_item_service.py`) effectue un calcul complet :

1. **Total depense** : somme de tous les `amount` des budget items
2. **Ventilation par categorie** : aggregation par `category`
3. **Budget total** : depuis `trip.budget_total`
4. **Confirme vs prevu** :
   - Confirme = items avec `source_type != null` OU `is_planned == false`
   - Prevu = items avec `is_planned == true` ET `source_type == null`
5. **Inclusion des activites** : requete sur `Activity` du trip :
   - VALIDATED ou MANUAL -> ajoute au confirme
   - SUGGESTED -> ajoute au prevu
6. **Alertes** :
   - Ratio >= 1.0 : `DANGER` + "Budget exceeded by X EUR"
   - Ratio >= 0.8 : `WARNING` + "X% of your budget has been used"

### Notifications budget

`NotificationService.check_and_send_budget_alert()` est appele apres chaque creation, mise a jour ou suppression d'un budget item. Il verifie le ratio depenses/budget et envoie une notification push `BUDGET_ALERT` si necessaire.

### Permissions

- Owner : CRUD complet + summary complet + estimation IA
- Viewer : summary reduit (uniquement totalBudget et percentConsumed), liste vide, detail interdit

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Reload summary apres CRUD | Le `BudgetBloc` fait un ajout/retrait optimiste dans `items` mais ne recharge pas le `summary` apres `Create`/`Update`/`Delete`. Le summary affiche des donnees potentiellement perimees (confirmedTotal, forecastedTotal, alertes). (`bagtrip/lib/budget/bloc/budget_bloc.dart:49-125`) | P0 |
| Endpoint estimation IA budget | L'event `EstimateBudget` appelle `budgetRepository.estimateBudget()` mais l'endpoint backend pour l'estimation budgetaire IA n'est pas visible dans `api/src/api/budget_items/routes.py`. A verifier dans les routes AI generiques. | P1 |
| Devise multi-monnaie | Le summary est en une seule devise. Pas de conversion automatique si des items sont dans des devises differentes. Le modele BudgetItem ne stocke pas de devise par item. | P2 |
| Graphiques de repartition | Pas de visualisation graphique (camembert, barres) de la repartition par categorie. Le `byCategory` est calcule mais affiche uniquement en texte. | P2 |
| Historique des alertes | Les alertes sont calculees a la volee mais pas historisees. Pas de tracking des notifications budget envoyees pour eviter les doublons. | P2 |
| Export du budget | Pas de fonctionnalite d'export CSV/PDF du budget. | P2 |
| Tests widget BudgetEstimateSheet | Le test `budget_item_form_test.dart` existe mais pas de test specifique pour le sheet d'estimation IA. | P2 |
