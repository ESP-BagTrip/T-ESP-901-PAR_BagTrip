# Accessibilite (a11y)

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip est concu pour rester utilisable au lecteur d'ecran (VoiceOver sur iOS, TalkBack sur Android), avec des cibles tactiles conformes aux Human Interface Guidelines (44x44 pt iOS) et aux Material Guidelines (48x48 dp Android), un support du Dynamic Type jusqu'a 1.5x sans overflow, et des contrastes de texte WCAG AA verifies par tests automatises.

L'effort se concentre sur quatre axes, materialises par quatre suites de tests dans `bagtrip/test/accessibility/` :

1. **AX1** : annotations semantiques (labels, roles, merge, exclude).
2. **AX2** : taille des cibles tactiles >= 44 pt.
3. **AX3** : tolerance au Dynamic Type 1.5x (pas d'overflow).
4. **AX4** : contraste des couleurs de texte >= 4.5:1 (texte normal) ou 3:1 (texte large).

Les helpers communs sont dans `bagtrip/test/accessibility/a11y_test_helpers.dart` (calcul de luminance WCAG 2.1, ratio de contraste, wrapper `MaterialApp` avec `textScale`, verification IconButton).

## Suites de tests AX1-AX4

| Suite | Fichier | Axe | Tests |
|-------|---------|-----|-------|
| AX1 | `test/accessibility/semantic_labels_test.dart` | Labels VoiceOver/TalkBack (OptimizedImage, ElegantEmptyState, MergeSemantics, ExcludeSemantics) | 4 |
| AX2 | `test/accessibility/touch_targets_test.dart` | Touch targets >= 44 pt (ActionChip pattern, TextButton minimumSize, IconButton 48x48) | 3 |
| AX3 | `test/accessibility/dynamic_type_test.dart` | Pas d'overflow a textScale 1.5 (ElegantEmptyState, ConstrainedBox, day chips) | 3 |
| AX4 | `test/accessibility/contrast_audit_test.dart` | Contraste WCAG AA des couleurs texte (textSecondary, textTertiary, textDisabled, textSecondaryDark, warningText) + sanity (black/white = 21:1) | 7 |

**Total : 17 tests** lances dans `make test-mobile` (`flutter test test/accessibility/`).

## Semantic labels

### Convention generale

- **Composants visuels reutilisables** (`OptimizedImage`, `TripCard`, `TimelineActivityCard`, `ActivityCard`, `ItemStatusChip`) exposent un `Semantics(label: ...)` au noeud racine et utilisent `excludeSemantics: true` pour empecher la propagation des sous-noeuds (sinon VoiceOver lit chaque texte interne en plus du label compose).
- **Labels localises** via `AppLocalizations` (jamais de chaine hardcodee). Exemple : `l10n.activityCardSemanticLabel(title, time, location, status)`.
- **Empty states** : `MergeSemantics` autour de l'icone + titre + sous-titre pour un seul noeud lisible d'un coup, et `ExcludeSemantics` autour du halo decoratif.

### ItemStatusChip — single source of truth

`bagtrip/lib/design/widgets/item_status_chip.dart` est le composant utilise par tout item de trip-detail (activite, vol manuel, hebergement, depense) pour annoncer son `validation_status`. Son noeud racine est un `Semantics(container: true, label: label)`, ou `label` est la chaine localisee (`itemStatusSuggested`, `itemStatusValidated`, `itemStatusManual`). Trois consequences :

1. Le lecteur d'ecran annonce le statut une seule fois meme en mode `compact` (icon-only) — l'icone seule serait muette sinon.
2. `fromBackend(raw)` fait fallback `manual` sur valeur inconnue : ajout d'un nouveau statut serveur = degradation gracieuse, jamais de crash a11y.
3. Le chip est `container: true`, ce qui empeche son icone interne de polluer le noeud parent (carte d'activite, sheet).

### Composants adaptatifs

`AdaptiveButton` (`lib/components/adaptive/adaptive_button.dart`) wrappe ses variantes iOS (Cupertino) et Android (Material) dans un `Semantics(button: true, label: ...)` au niveau racine — necessaire car `CupertinoButton` n'expose pas le role bouton par defaut.

`AdaptiveTextField` annote le champ avec `Semantics(textField: true)` (Cupertino n'a pas le role `TextField` natif que `Material` injecte automatiquement).

## Touch targets (44x44 iOS, 48x48 Android)

| Composant | Mecanisme | Resultat |
|-----------|-----------|----------|
| `IconButton` | Defaut Flutter `kMinInteractiveDimension = 48.0` | Tap target 48x48, conforme iOS et Android |
| `TextButton` / `ElevatedButton` | Theme global `minimumSize: Size.fromHeight(42)` + padding `AppSpacing.allEdgeInsetSpace16` | Hauteur effective >= 44 |
| ActionChip (pattern timeline) | `ConstrainedBox(constraints: BoxConstraints(minHeight: 44))` autour de l'`InkWell` | 44 pt verifie par AX2 |
| `MaterialTapTargetSize` | **Jamais `shrinkWrap`** sur un element interactif | Garanti par test `'No MaterialTapTargetSize.shrinkWrap on interactive elements'` |

Le test `AX2 — IconButton default touch target is at least 44pt` lit le `RenderBox` du `IconButton` et asserte `size.width >= 44 && size.height >= 44` — gate explicite contre une regression future qui passerait `iconSize: 16` sans constraints.

## Dynamic Type

iOS et Android permettent a l'utilisateur d'augmenter la taille du texte systeme (Reglages > Accessibilite > Taille du texte). BagTrip cible un support **jusqu'a 1.5x sans overflow** :

- Composants critiques (`TripCard`, `ElegantEmptyState`, `DayChipRow`, hero header) utilisent `ConstrainedBox(constraints: BoxConstraints(minHeight: X))` au lieu de `SizedBox(height: X)`. Le contenu peut grandir au-dela du min sans casser.
- Les blocs susceptibles de deborder sont dans un `SingleChildScrollView` (empty states pleins ecran, sheets d'edition).
- Pas de `ClipRect` agressif autour des textes (la troncature est geree par `maxLines` + `overflow: TextOverflow.ellipsis` au cas par cas).

La suite AX3 verifie les trois patterns canoniques :

1. `ElegantEmptyState` avec subtitle long + CTA dans un `SingleChildScrollView` a textScale 1.5 — `tester.takeException()` doit etre `null`.
2. `ConstrainedBox(minHeight: 200)` avec 3 textes empiles : la hauteur rendue est `>= 200` (peut grandir).
3. `DayChipRow` simule (ConstrainedBox + ListView horizontal de chips) ne leve aucune exception a 1.5x.

Le wrapper de test injecte le scaler via `MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(textScale)))`.

## Contrast WCAG AA

Toutes les couleurs de texte exposees par `AppColors` (`bagtrip/lib/design/app_colors.dart`) sont **pre-calculees pour respecter WCAG AA** (ratio >= 4.5:1 pour le texte normal, >= 3:1 pour le texte large >= 18 pt bold). Les valeurs sont commentees inline avec leur ratio :

| Token | Sur fond | Ratio mesure |
|-------|----------|--------------|
| `textSecondary` (`0xFF5B6A7B`) | blanc | 5.2:1 |
| `textTertiary` (`0xFF4A5568`) | blanc | 6.3:1 |
| `textDisabled` (`0xFF6B7280`) | blanc | 4.6:1 (minimum AA) |
| `textSecondaryDark` (`0xFFB0BEC5`) | `primaryTrueDark` | 4.5:1 |
| `warningText` (`0xFFE65100`) | `warningBg` (`0xFFFFF3E0`) | >= 3:1 (large text AA) |

La suite AX4 verifie chaque token via `contrastRatio(fg, bg)` (formule WCAG 2.1) et echoue le test si le ratio descend sous le seuil. Deux tests sanity garantissent la formule elle-meme : `black/white = 21.0` et `red/red = 1.0`.

**Regle stricte** : aucune couleur `Colors.<material>` directe dans `lib/` (`Colors.grey`, `Colors.blue`, etc.). Tout passe par `AppColors.*` ou `ColorName.*` — c'est verifie a la review.

## Helpers

`bagtrip/test/accessibility/a11y_test_helpers.dart` :

- `buildTestableWidget(Widget child, {double textScale = 1.0})` — wrappe `child` dans un `MaterialApp` configure (l10n delegates, locale `en`, theme `AppTheme.light()`, `MediaQuery` avec `TextScaler.linear(textScale)`). Utilise par AX1, AX2, AX3.
- `relativeLuminance(Color)` — luminance relative WCAG 2.1 (gamma sRGB + ponderation 0.2126/0.7152/0.0722).
- `contrastRatio(Color fg, Color bg)` — ratio `(L1 + 0.05) / (L2 + 0.05)` avec `L1` = max et `L2` = min. Retourne une valeur dans `[1.0, 21.0]`.
- `expectMinimumTouchTargets(WidgetTester, {double minSize = 44.0})` — itere les `IconButton` du tree et asserte une taille d'icone >= 24 px (le tap target reste >= 48 grace au comportement Flutter par defaut).

Tout nouveau test d'accessibilite doit reutiliser ces helpers — ne jamais recalculer un ratio de contraste ou rebatir un `MaterialApp` de test ailleurs.

## Ce qu'il manque

| Sujet | Description | Priorite |
|-------|-------------|----------|
| Semantics formulaires | `AdaptiveTextField` annote le champ mais les ecrans de PlanTrip (wizard 6 etapes) et de booking n'ont pas de `Semantics(textField: true, label: ...)` explicites au-dela du composant. VoiceOver decrit generiquement. | P1 |
| Traverse order VoiceOver | Pas de `OrdinalSortKey` dans les ecrans denses (trip detail, timeline) : l'ordre de lecture suit la position visuelle, ce qui peut surprendre quand des chips et CTA sont colocalises. | P1 |
| Bottom sheets | Les sheets ouvertes via `showModalBottomSheet` n'emettent pas de `Semantics(label: ...)` annoncant leur titre a l'ouverture. | P1 |
| Contrastes dark mode | Seul `textSecondaryDark` est teste sur `primaryTrueDark`. Les autres surfaces dark n'ont pas d'audit automatise. | P1 |
| Tests des composants adaptatifs | `AdaptiveDialog`, `AdaptiveActionSheet`, `AdaptiveDatePicker`, `AdaptiveTimePicker` n'ont pas de suite a11y dediee. | P2 |
| Support > 1.5x | iOS permet jusqu'a ~3.5x (tailles d'accessibilite XXL). Certains layouts (hero header, day chips serres) cassent vraisemblablement entre 2x et 3x. | P2 |
| Focus management | Pas de gestion explicite du focus pour switch control / clavier externe dans les flows multi-etapes (PlanTrip, post-trip feedback). | P2 |
| Audit automatise exhaustif | Pas de `flutter test --accessibility` ou de package `accessibility_tools` integre en CI. Seuls les composants explicitement listes dans les suites AX1-AX4 sont couverts. | P2 |
