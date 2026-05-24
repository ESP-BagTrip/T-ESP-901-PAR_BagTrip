# Budget

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

Le module Budget est l'un des piliers de BagTrip : il permet a l'utilisateur de fixer un objectif chiffre pour son voyage, de tracker chaque depense (planifiee comme reelle) et d'etre alerte lorsque le voyage derape financierement. Le calcul agrege deux sources : les lignes saisies dans `budget_items` (vols, hebergements, repas, transport local, shopping, autre) et le cout des `activities` validees / suggerees, qui restent leur propre source de verite depuis SMP-324.

Le module expose une CRUD complete, un summary calcule cote serveur, une estimation IA via le `budget_node` du graphe LangGraph et un quick add depuis le mode in-trip. La feature est entierement role-aware : un viewer ne voit jamais les montants exacts, le serveur les masque via `redact_budget_summary_for_role` (topic B9 du kanban SMP-322).

Le "kanban budget" auquel les commits font reference (SMP-322) n'est pas un widget kanban dans l'UI : c'est l'organisation interne de la refonte budget en topics (B1 a B11) sous un seul ticket Jira. Tout vit sous `task/smp-322`.

## Cote Backend

### Modele BudgetItem

`api/src/models/budget_item.py`. Champs cles :

- `id`, `trip_id` (FK trips), `label`, `amount` (`Numeric(12,2)`)
- `currency` : devise saisie (defaut EUR). Conversion vers `trip.currency` au moment de l'agregation via `CurrencyService.convert()`.
- `category` : string libre, valeurs canoniques `FLIGHT`, `ACCOMMODATION`, `FOOD`, `ACTIVITY`, `TRANSPORT`, `OTHER`. Defaut `OTHER`.
- `date` (date optionnelle), `is_planned` (bool, defaut True)
- `source_type` / `source_id` : lien optionnel vers une ressource externe (`flight_order`, `accommodation`...) pour tracer une ligne creee automatiquement.
- `validation_status` : `SUGGESTED` (IA), `VALIDATED` (revu par l'owner), `MANUAL` (saisie utilisateur, defaut). Memes regles de transition que les autres domaines : seul `SUGGESTED -> VALIDATED` est autorise.
- `created_at`, `updated_at`

Index dedie `ix_budget_items_source` sur `(source_type, source_id)` pour le lookup `find_by_source`.

### Endpoints

Tous prefixes `/v1/trips/{tripId}/budget-items` (ou `/budget/...` pour l'IA), guard `TripAccess` :

| Methode | Route | Acces | Description |
|---|---|---|---|
| POST | `/budget-items` | editor | Cree une ligne. Body `label, amount, category?, date?, isPlanned?, validationStatus?`. Declenche `NotificationService.check_and_send_budget_alert`. |
| GET | `/budget-items` | viewer (liste vide), editor | Liste ordonnee par `created_at desc`. |
| GET | `/budget-items/summary` | viewer (redacte), editor | Summary agrege passe par `redact_budget_summary_for_role`. |
| GET | `/budget-items/{itemId}` | editor | Detail. 403 pour viewer. |
| PUT | `/budget-items/{itemId}` | editor | Update partielle. Refuse les downgrades de `validation_status`. |
| DELETE | `/budget-items/{itemId}` | editor | 204. Refuse si `trip.status == COMPLETED`. |
| POST | `/budget/estimate` | editor + `require_ai_quota` | Estimation IA via `budget_node`. Incremente le compteur quota. |
| POST | `/budget/estimate/accept` | editor | Ecrit `trip.budget_estimated` (PAS `budget_target` qui reste l'intention de l'utilisateur). |

### Calcul du summary

`BudgetItemService.get_budget_summary(db, trip)` :

1. Recupere les `BudgetItem` du trip, convertit chaque `amount` vers `trip.currency` via `currency_service.convert`.
2. Recupere les `Activity` du trip (single source of truth pour leur cout depuis SMP-324) et somme `estimated_cost`.
3. `total_spent = items_total + activities_total`.
4. `by_category` : map agregee. Les activites sont projetees sous la cle `ACTIVITY`.
5. **Confirme vs prevu** :
   - Item confirme : `source_type != null` OU `is_planned == false`
   - Item prevu : `is_planned == true` ET `source_type == null`
   - Activite confirmee : `validation_status` IN (`VALIDATED`, `MANUAL`)
   - Activite prevue : `validation_status == SUGGESTED`
6. **Alertes** vs `trip.budget_target` (l'intention utilisateur, jamais `budget_estimated`) :
   - ratio >= 1.0 -> `alert_level = DANGER`, message `"Budget exceeded by X EUR"`
   - ratio >= 0.8 -> `alert_level = WARNING`, message `"X% of your budget has been used"`

Retour : `total_budget`, `budget_target`, `budget_estimated`, `budget_actual`, `total_spent`, `remaining`, `by_category`, `alert_level`, `alert_message`, `confirmed_total`, `forecasted_total`.

### Estimation IA

`POST /v1/trips/{tripId}/budget/estimate` construit un `TripPlanState` minimal depuis les donnees du trip (destination, dates, voyageurs, activites, hebergements) puis appelle `budget_node` (LangGraph, `src/agent/nodes/budget.py`). Le node est devenu deterministe (SMP-324) : il n'utilise plus de ReAct executor mais agrege les couts par poste avec les regles metier. Retour : `accommodationPerNight`, `mealsPerDayPerPerson`, `localTransportPerDay`, `activitiesTotal`, `totalMin`, `totalMax`, `currency`, `breakdownNotes`.

`POST /budget/estimate/accept` ecrit `trip.budget_estimated` directement (bypass `TripsService.update_trip` qui interdit cette ecriture) puis re-evalue les alertes.

### Securite : redact_for_viewer (topic B9)

`api/src/api/common/redaction.py` centralise la regle "un champ masque ne doit jamais etre reconstructible depuis un autre champ expose". Pour un viewer, `redact_budget_summary_for_role` retourne :

- `total_budget` / `budget_target` : la cible (visible, fait partie de l'invitation de partage)
- `budget_estimated`, `budget_actual`, `total_spent`, `remaining`, `confirmed_total`, `forecasted_total` : tous a 0 ou null. La regle critique : `percent_consumed` est aussi force a null, sinon le viewer pourrait recalculer `total_spent = target * percent`.
- `by_category` : vide
- `alert_level` / `alert_message` : null (le message contient le delta exact, donc fuite)
- `budget_status` : bucket semantique a la place. `onTrack` (< 80%), `tight` (80-99%), `overBudget` (>= 100%), null si pas de cible.

C'est le seul champ que le viewer obtient sur l'etat reel du budget. Meme un build mobile tamponne ne peut pas afficher ce qu'il n'a pas recu.

## Cote Mobile

### BudgetPanel

`bagtrip/lib/trip_detail/view/panels/budget_panel.dart` est branche dans le `TripDetailBloc` (events `CreateBudgetItemFromDetail`, `UpdateBudgetItemFromDetail`, `DeleteBudgetItemFromDetail`). Aucun BLoC dedie : tout passe par le hub du trip detail conformement a la regle architecturale.

Layout (editor / owner) :

- `BudgetAlertBanner` quand `summary.alertLevel != null`
- `_DualTotalCard` : deux colonnes serif (Real vs Forecasted) + delta en pied
- Section "Forecast" : items `is_planned == true` + activites `SUGGESTED`
- Section "Real" : items `is_planned == false` + activites `VALIDATED`/`MANUAL`
- `PanelFab` "Quick add expense" en bas a droite
- Tap item -> `QuickPreviewSheet` avec actions Edit / Delete
- Swipe item -> dismissal avec confirmation tactile
- Long-press -> `AdaptiveContextMenu`

Les activites sont rendues en read-only (`_ActivityExpenseRow`) : leur cout vit dans le panel Activities, jamais edite ici.

Layout viewer (`_ViewerBudgetPanel`) : carte unique avec la cible chiffree + pill `budget_status` (`On track`, `Tight`, `Over budget`) + hint `budgetViewerNoFiguresHint`. Aucune liste, aucun montant detaille.

### BudgetItemForm

`bagtrip/lib/budget/widgets/budget_item_form.dart` est branche dans `showItemFormSheet` (chrome standardise SMP-324). Champs : label, amount, category (chips `BudgetCategory`), date picker adaptatif, toggle "Planned / Confirmed" (pill segmented). Le `validation_status` est gere via `ItemStatusChip` dans le header du scaffold.

### Quick expense (in-trip)

`bagtrip/lib/home/cubit/quick_expense_cubit.dart` + `home/widgets/quick_expense_sheet.dart`. Branche dans la home pendant un voyage en cours : un seul tap depuis la bottom bar ouvre une bottom sheet minimaliste (amount + 4 chips Food/Transport/Activity/Other + note optionnelle).

Le cubit appelle `BudgetRepository.createBudgetItem` avec :
- `label` = note saisie ou nom de la categorie en upper case
- `amount`, `category`, `isPlanned = false` (la depense est immediate)
- `date` = aujourd'hui

States : `Initial`, `Saving`, `Saved`, `Error`. Le sheet ferme automatiquement sur `Saved` avec haptic `success`.

### Repository et cache

`bagtrip/lib/repositories/budget_repository.dart` definit l'interface (`getBudgetItems`, `getBudgetSummary`, CRUD, `estimateBudget`, `acceptBudgetEstimate`). `CachedBudgetRepository` (`lib/service/cached_budget_repository.dart`) wrap le remote :

- Lecture : cache Hive `budget_cache`, fallback online -> cache, refresh systematique en ligne.
- Ecriture : si offline et `OfflineWriteQueue` enregistre, enqueue de l'operation (`budget:createBudgetItem`, `:update`, `:delete`) pour replay au retour online. Invalidation cache apres ecriture reussie.

## Categories

L'enum mobile `BudgetCategory` est mappe via `BudgetCategoryPresentation` (`lib/design/category_mappers.dart`) — source unique de verite (icon + label l10n) reutilisee par le form, le panel et le quick add.

| Categorie | Cle backend | Icon | Label l10n |
|---|---|---|---|
| Vols | `FLIGHT` | `Icons.flight` | `reviewBudgetFlights` |
| Hebergement | `ACCOMMODATION` | `Icons.hotel` | `reviewBudgetAccommodation` |
| Repas | `FOOD` | `Icons.restaurant` | `reviewBudgetMeals` |
| Activites | `ACTIVITY` | `Icons.sports_tennis` | `reviewBudgetActivities` |
| Transport | `TRANSPORT` | `Icons.directions_car` | `reviewBudgetTransport` |
| Autre | `OTHER` | `Icons.receipt_long` | `reviewBudgetOther` |

Couleurs : pas de mapping color dedie dans `BudgetCategoryPresentation` (contrairement aux activites). Le panel utilise `ColorName.primary` pour les items budget et `ColorName.secondary` pour les activites projetees, afin de distinguer visuellement les deux sources.

## Flux

### Saisie d'une depense (in-trip)

1. User tape "+" depuis la home pendant un voyage actif.
2. `QuickExpenseSheet` ouvre avec autofocus sur le montant.
3. Submit -> `QuickExpenseCubit.saveExpense` -> POST `/budget-items` avec `isPlanned = false`.
4. Succes -> haptic + close. Le `TripDetailBloc` rafraichira au prochain retour sur la fiche.

### Estimation IA + acceptation

1. User clic sur "Estimer le budget" (entry point dans le wizard de creation ou la fiche trip).
2. Front POST `/budget/estimate`. Loader avec shimmer.
3. Backend assemble le state, appelle `budget_node`, incremente le quota IA, retourne le breakdown.
4. User clic "Accepter" -> POST `/budget/estimate/accept` avec `budget_estimated = (totalMin + totalMax) / 2`.
5. Backend ecrit `trip.budget_estimated` (pas `budget_target`) et recalcule les alertes.

### Visualisation viewer

1. Viewer ouvre l'onglet Budget.
2. GET `/budget-items` -> liste vide (court-circuit serveur).
3. GET `/budget-items/summary` -> dict redacte (`total_spent=0`, `percent_consumed=null`, `budget_status` bucket).
4. Le panel detecte `role == 'VIEWER'` et rend `_ViewerBudgetPanel` (target + bucket + hint).

## Ce qu'il manque

| Element | Description | Priorite |
|---|---|---|
| Multi-currency runtime | `currency_service.convert` est stub a rate 1.0 (Phase 1). L'integration ECB pour les taux temps reel est planifiee mais pas live. Tant que c'est stub, tout est traite comme EUR meme si l'item est saisi en USD. | P1 |
| Color tokens par categorie budget | `BudgetCategoryPresentation` n'expose pas de `color` getter contrairement a `ActivityCategoryPresentation`. Le panel utilise `ColorName.primary` uniforme. | P2 |
| Graphiques de repartition | `by_category` est calcule mais affiche en texte/liste uniquement. Pas de camembert ni de barres horizontales. | P2 |
| Historique des alertes | Les notifications BUDGET_ALERT sont envoyees a chaque CRUD mais ne sont pas dedupliquees sur fenetre. Risque de spam si l'utilisateur edite plusieurs items consecutifs au-dessus de 80%. | P2 |
| Export budget | Pas d'export CSV / PDF. La trace reste dans l'app. | P3 |
| Tests widget panel viewer | Le rendu `_ViewerBudgetPanel` n'a pas de test golden ou widget dedie verifiant qu'aucun montant detaille ne fuit. | P2 |
| Edition des activites depuis le panel budget | Volontairement absent (les activites editent dans leur propre onglet) mais cree un aller-retour quand l'utilisateur veut ajuster un cout d'activite depuis le budget. UX a discuter. | P3 |
