# Design system mobile

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

Le design system de BagTrip vit dans trois couches imbriquees : tokens primitifs (espacements, rayons, ombres, animations) dans `lib/design/tokens.dart`, palette semantique (`AppColors`) qui wrap la palette brute fluttergen (`ColorName`), et composants reutilisables (adaptatifs Material/Cupertino, briques trip-detail SMP-324, empty states, sheets, FAB pattern). Aucun composant ne hardcode une valeur de couleur, d'espace ou de rayon : si le token manque, il s'ajoute dans le bon fichier, jamais inline.

La regle d'or : tout ce qui touche au visuel passe par un token ou un composant deja existant. La duplication d'un `Color(0xFF...)`, d'un `BorderRadius.circular(20)` ou d'un `Platform.isIOS` est consideree comme une dette a refactor lors de la review.

Les composants adaptatifs sont l'epine dorsale du multi-plateforme : ils prennent la decision Material/Cupertino une seule fois et exposent une API neutre que les pages consomment sans condition `if (Platform.isIOS)`. Pour le check direct quand il faut diverger plus fond (ex : FAB Android vs IconButton AppBar iOS), on passe toujours par `AdaptivePlatform.isIOS`, jamais par `Platform.isIOS`.

## Tokens

Tous declares dans `lib/design/tokens.dart`. Chaque classe est un namespace prive (`const ClassName._()`), aucune instance n'est creee.

### AppSpacing

| Token | Valeur | Usage type |
|---|---|---|
| `space4` | 4 px | gaps inter-icones, vertical chip padding |
| `space8` | 8 px | gaps inter-rows, padding compact |
| `space12` | 12 px | drag handle padding, chip horizontal |
| `space15` | 15 px | CTA principal Plan trip wizard (vertical) |
| `space16` | 16 px | padding standard cards / sheets |
| `space22` | 22 px | marge horizontale Plan trip (densite Ive) |
| `space24` | 24 px | section spacing |
| `space32` | 32 px | bottom padding scrollable Android |
| `space40` / `space48` / `space56` | 40 / 48 / 56 px | hero blocks, large gutters |

EdgeInsets pre-calcules : `allEdgeInsetSpace{4,8,12,16,24,32,40,48}`, `horizontalSpace{4,8,12,16,22,24}`, `verticalSpace{4,8,12,15,16,24}`, `onlyTopSpace{8,16,24}`, `onlyBottomSpace{8,16,24}`, `onlyLeftSpace{8,16}`, `onlyRightSpace{8,16}`. Toujours preferer un EdgeInsets pre-calcule a un `EdgeInsets.all(AppSpacing.spaceN)` inline.

### AppRadius

| Token | Valeur | Usage |
|---|---|---|
| `cornerRadius2` | 2 | dots indicator, swatches |
| `cornerRadius3` | 3 | page indicator paywall |
| `cornerRaidus4` / `cornerRaidus8` | 4 / 8 | chips, petits inputs |
| `cornerRadius12` | 12 | inputs medium |
| `cornerRadius13` | 13 | context pill Plan trip header |
| `cornerRaidus16` | 16 | cards standard |
| `cornerRadius20` | 20 | tops de bottom sheets |
| `cornerRadius24` / `cornerRadius28` | 24 / 28 | hero cards |
| `cornerRadius32` | 32 | sections premium |
| pill | 999 | status chip, badge |

`BorderRadius` precomputes : `small4`, `medium8`, `medium12`, `large13`, `large16`, `large20`, `large24`, `large28`, `large32`, `pill`, `handleBar` (drag handle 40x4), `dot` (page indicator). Pour un radius hors liste, le creer dans `tokens.dart` plutot que `BorderRadius.circular(X)` inline.

### AppSize

`height42` / `width42` (CTA height standard), `iconSizeHeight24`, `boxSize8`, `boxSize16`. Liste volontairement courte : la majorite des sizes restent contextuelles.

### AppShadows

Trois constantes : `cardPrimary` (drop shadow 8% alpha, offset (0,4), blur 6), `cardAmbient` (companion 4% alpha, offset (0,2), blur 4), et `card` qui combine les deux. C'est ce que 90% des cards utilisent : `boxShadow: AppShadows.card`. Avant ce token, ~30 cards portaient un `BoxShadow(color: ColorName.primary.withValues(alpha: 0.08), ...)` copie-colle.

### AppAnimationDurations

| Token | Duree | Usage |
|---|---|---|
| `microInteraction` | 150 ms | tap ripples, icon flips |
| `quick` | 200 ms | chip hover, subtle reveals |
| `standard` | 300 ms | bottom sheets, list item mutations |
| `lengthy` | 600 ms | hero transitions, celebrations |

Toute `Duration(milliseconds: ...)` codee en dur dans un widget est un smell : si la valeur ne matche pas un des 4 tokens, c'est probablement un bug de tempo.

## Couleurs

Deux niveaux. `ColorName` (`lib/gen/colors.gen.dart`) est genere par fluttergen depuis `assets/color/colors.xml` et expose la palette brute (primary `#295F98`, secondary `#35A8B5`, primaryTrueDark `#0E2135`, etc.). `AppColors` (`lib/design/app_colors.dart`) wrap cette palette en tokens semantiques : `AppColors.surface`, `AppColors.primary`, `AppColors.textSecondary`, `AppColors.success`, `AppColors.error`.

Categories :

- Surfaces : `surface`, `surfaceLight`, `surfaceDark`, `surfaceVariant`.
- Text accessible (contraste AA precalcule) : `textSecondary` (5.2:1 sur blanc), `textTertiary` (6.3:1), `textDisabled` (4.6:1 minimum AA), `textSecondaryDark` (4.5:1 sur fond `#0E2135`).
- Brand : `primary`, `primaryDark`, `primaryLight`, `primarySoftLight`, `primaryTrueDark`, `secondary`, `secondaryLight`.
- Status : `success`, `warning`, `warningLight`, `error`, `errorDark`, `info`, `infoLight`.
- Categories activite (foreground tints) : `activityCulture` (indigo), `activityNature` (green), `activityFood` (deepOrange), `activitySport` (blue), `activityShopping` (purple), `activityNightlife` (deepPurple), `activityRelaxation` (teal).
- Categories budget : pastel light (`categoryFlight`, `categoryAccommodation`, ...) + variante dark (`categoryFlightDark`, ...) + resolver `categoryFlightOf(Brightness)` qui retourne la bonne variante selon le theme.
- Plan trip step accents : `stepInProgress`, `stepInProgressSubtitle`, `stepCompletedSubtitle`, `stepProgressGlow`, `stepSuccessBg`, `stepSuccessBorder`.
- Review step (warm grays) : `reviewMuted`, `reviewSubtle`, `reviewFaint`, `reviewInk`, `reviewUnchecked`, `reviewDivider`, `reviewBorderLight`, `reviewHeroDark`.
- Banners : `dangerBg/Border/Icon/Text`, `warningBg/Border/Icon/Text`, `errorBg/Text`.
- Shadows ad-hoc : `shadowLight` (6% noir), `shadowSubtle` (4% noir), `shadowFaint` (2% noir).

Les category mappers consomment `AppColors.activityXxx` via les extensions `ActivityCategoryPresentation` et `BudgetCategoryPresentation` (`lib/design/category_mappers.dart`), qui exposent `.icon`, `.color` et `.label(l10n)`. Avant ces extensions, le switch icone/couleur etait duplique dans 4 fichiers (activity_card, activity_form, timeline_activity_card, timeline_activity_row).

Le theme global est defini dans `lib/design/app_theme.dart` : `AppTheme.light()`, `AppTheme.dark()`, et les variantes Cupertino `cupertinoLight()` / `cupertinoDark()` consommees par l'`AdaptiveScaffold` et le `MaterialApp`. Le `seedColor` est `ColorName.primary` (light) ou `ColorName.secondary` (dark).

## Typography

Trois familles disponibles dans `lib/gen/fonts.gen.dart` : `FontFamily.b612` (UI primaire), `FontFamily.dMSans`, `FontFamily.dMSerifDisplay` (hero / serif accents). En pratique, tout passe par `B612` qui est defini comme `fontFamily` global dans `AppTheme` et `CupertinoTextThemeData`.

Hierarchie textuelle (definie dans `AppTheme.light()` et `dark()`) :

| Style | Poids | Couleur light | Usage |
|---|---|---|---|
| `titleLarge` | w700 | `ColorName.primary` | titres pages |
| `titleMedium` | w700 | `ColorName.primaryTrueDark` | titres sections / cards |
| `bodyMedium` | regular | `ColorName.primaryTrueDark` | corps de texte |
| `labelLarge` | w600 | `AppColors.surface` (blanc) | labels CTA |

Pour les chiffres et codes IATA (vols), `B612` est conserve volontairement (alignement monospace-friendly). Aucune typo ne doit etre ecrite avec `fontFamily: 'something'` en chaine litterale : passer par `FontFamily.b612`.

## Extensions

### DateTimeExt (`lib/core/extensions/datetime_ext.dart`)

- `dt.daysUntilNow` : nombre de jours entiers de `dt` a maintenant (calendar-day truncation, donc "demain a 01:00" = 1 jour quel que soit l'heure courante). Negatif si `dt` est passe.
- `dt.daysSinceNow` : oppose de `daysUntilNow`.
- `checkIn.nightsUntil(checkOut)` : nuits entre deux dates, clamped a 1 minimum (un same-day check-in/out compte 1 nuit pour le pricing).
- `departure.flightDurationTo(arrival)` : format `"2h05"`, clampe a `"0h00"` si negatif.

Avant ces extensions, chaque card avait son propre `var nights = a.checkOut!.difference(a.checkIn!).inDays; if (nights < 1) nights = 1;` recopie 5+ fois.

### PriceFormatExt (`lib/core/extensions/price_format_ext.dart`)

`price.formatPrice()` produit `"123 EUR"` (defaut `currency: 'EUR'`). Single source of truth pour le format prix : si on bascule un jour sur `NumberFormat.simpleCurrency`, c'est ici qu'on change, pas dans 20 widgets.

## Composants adaptatifs

Tous dans `lib/components/adaptive/`. Les pages consomment l'API neutre et ne savent pas si elles tournent sur Material ou Cupertino. Le check de plateforme se fait via `AdaptivePlatform.isIOS` (`lib/core/platform/adaptive_platform.dart`), jamais `Platform.isIOS` direct.

| Composant | Fichier | Android | iOS |
|---|---|---|---|
| `AdaptiveButton` | `adaptive_button.dart` | `ElevatedButton` width=infinity | `CupertinoButton.filled` |
| `AdaptiveAppBar.build(...)` | `adaptive_app_bar.dart` | `AppBar` | `GlassAppBar` + auto back button si `canPop` |
| `showAdaptiveAlertDialog` | `adaptive_dialog.dart` | `AlertDialog` | `CupertinoAlertDialog` |
| `showAdaptiveEditDialog` | `adaptive_edit_dialog.dart` | `AlertDialog` + `TextFormField` | `CupertinoAlertDialog` + `CupertinoTextField` |
| `showAdaptiveActionSheet` | `adaptive_action_sheet.dart` | bottom sheet Material + ListTiles | `CupertinoActionSheet` |
| `AdaptiveTextField` | `adaptive_text_field.dart` | `TextFormField` outlined | `CupertinoTextField` systemGrey6 bg |
| `showAdaptiveDatePicker` | `adaptive_date_picker.dart` | `showDatePicker` Material | `CupertinoDatePicker` modal popup |
| `showAdaptiveTimePicker` | `adaptive_time_picker.dart` | `showTimePicker` clock | `CupertinoDatePicker` mode time |
| `AdaptiveScaffold` | `adaptive_scaffold.dart` | `Scaffold` | `CupertinoPageScaffold` + SafeArea |
| `AdaptiveIndicator` | `adaptive_indicator.dart` | `CircularProgressIndicator` | `CupertinoActivityIndicator` (via `.adaptive()`) |
| `AdaptiveContextMenu` | `adaptive_context_menu.dart` | passthrough (child inchange) | `CupertinoContextMenu.builder` |

`AdaptiveButton` et `AdaptiveTextField` injectent automatiquement les `Semantics` necessaires (label, role, enabled). Les dialogs prennent `confirmLabel` et `cancelLabel` localises par le caller — ils n'ont pas de strings hardcodes.

Helper generique `AdaptivePlatform.select<T>(material: ..., cupertino: ...)` quand un widget custom doit choisir une valeur sans creer un composant adaptatif dedie.

## FAB pattern

L'app utilise deux affordances pour les actions de creation rapide, choisies par plateforme :

- **Android** : `FloatingActionButton.extended(...)` dans `Scaffold.floatingActionButton`.
- **iOS** : `IconButton(icon: Icon(CupertinoIcons.add))` dans `AppBar.actions`.

Le switch passe par `AdaptivePlatform.isIOS` directement (pas de wrapper, c'est trop divergent en placement pour un composant unique).

Regle critique : **jamais** de FAB et CTA empty state simultanes. Quand la liste est vide, seul le CTA de l'`ElegantEmptyState` reste visible (FAB masque). Quand la liste contient au moins un item, le CTA empty state disparait et seul le FAB / icone AppBar reste. Ca evite le doublon visuel "Ajouter ma premiere depense" + bouton flottant qui distrait l'oeil.

## Bottom sheets

Tout `showModalBottomSheet` suit la meme convention : fond transparent (`backgroundColor: Colors.transparent`), Container interne avec radius haut 20, drag handle bar 40x4 centree, `isScrollControlled: true` quand le contenu peut depasser.

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: AppRadius.handleBar,
            ),
          ),
        ),
        // contenu
      ],
    ),
  ),
);
```

Pour les formulaires d'edition d'item trip-detail, ne pas reinventer ce chrome : passer par `showItemFormSheet(...)` + `ItemFormScaffold` (cf. section SMP-324). Idem pour un flow remplacer-via-recherche : `showReplaceSearchSheet(...)`.

**Chaining de sheets** : un piege classique est d'ouvrir une sheet B depuis une sheet A en appelant `Navigator.pop` puis `showModalBottomSheet` avec le meme `context`. Le `context` capture par la sheet A est invalide apres `pop`. La regle : capturer le bloc parent et le context parent **avant** le `pop`.

```dart
final bloc = context.read<MyBloc>();
final parentContext = context;
Navigator.of(context).pop();
showModalBottomSheet(
  context: parentContext,
  builder: (_) => BlocProvider.value(value: bloc, child: ...),
);
```

## Patterns trip-detail SMP-324

Quatre briques portent toute l'UX trip-detail. Tout nouveau type d'item (Activity, ManualFlight, Accommodation, BudgetItem, futurs domaines) consomme ces 4 composants par defaut au lieu de les reinventer.

### ItemStatusChip (`lib/design/widgets/item_status_chip.dart`)

Single source of truth pour le rendu visuel de `validation_status`. Enum `ItemStatusChipKind` : `suggested` (halo dore `#FFF4D6` + icone `auto_awesome`), `validated` (vert + `check_circle`), `manual` (gris + `edit_note`).

Modes `compact: true` (icone seule, dense card header) ou `compact: false` (icone + label localise via `l10n.itemStatusSuggested/Validated/Manual`). `Semantics(container: true, label: ...)` integre pour l'a11y.

Adapter `ItemStatusChip.fromBackend(raw)` mappe la string backend (`"SUGGESTED"` / `"VALIDATED"` / `"MANUAL"`) vers l'enum, avec fallback `manual` sur unknown — un nouveau statut ajoute cote serveur ne crash pas le client.

### ItemFormScaffold + showItemFormSheet (`lib/design/widgets/item_form_scaffold.dart`)

Chrome standardise pour TOUT formulaire d'edition d'item. Owne drag handle, keyboard padding (`viewInsetsOf`), top radius 20, header avec `ItemStatusChip` optionnel, scroll, slot actions (boutons primary + secondary en `Row` egal). Le form ne ship que ses champs propres (`fields`), son titre, son subtitle optionnel, son `statusKind` et la liste `actions`.

Constante `ItemFormSheetLayout.maxHeightFactor = 0.8` : la sheet ne depasse jamais 80% de l'ecran (place pour la scrim et le swipe-to-dismiss).

Le helper `showItemFormSheet(context: ..., child: ItemFormScaffold(...))` standardise l'ouverture (transparent barrier, scroll-controlled, alignement bas).

### QuickPreviewSheet (`lib/design/widgets/review/sheets/quick_preview_sheet.dart`)

Sheet d'apercu legere quand l'utilisateur tape un item dans un panel. Slots :

- `validateAction` : priorise Validate en CTA primaire quand l'item est SUGGESTED — promotion automatique, le `primaryAction` (Edit / Replace) recule en secondaire.
- `primaryAction` : CTA principal (Edit, Replace).
- `secondaryAction` : action mineure.
- `destructiveAction` : suppression.
- `openFullLabel` + `onOpenFull` : footer opt-in qui navigue vers la sous-page complete.

`DraggableScrollableSheet` avec `initialChildSize: 0.55`, `minChildSize: 0.35`, `maxChildSize: 0.92` — l'utilisateur peut tirer la sheet jusqu'a quasi plein ecran sans naviguer. Viewer-mode passe `primaryAction: null` pour masquer toute action mutative.

### ReplaceSearchSheet + showReplaceSearchSheet (`lib/design/widgets/replace_search_sheet.dart`)

Sheet plein ecran (95% de la hauteur) pour wrap un search-and-replace flow (vols, hotels). Le caller compose l'inner widget tree (formulaire de recherche, resultats, confirmation) — la sheet owne seulement le chrome (rounded top 20, header avec close button, divider, hauteur).

`isDismissible: false` et `enableDrag: false` : le tap-outside dismiss est desactive volontairement pour preserver le state mid-search (l'utilisateur doit explicitement cancel via le bouton close). Le bloc handler atomique cote detail (ex : `ReplaceFlightFromDetail`) est responsable du DELETE+CREATE avec rollback.

### Repository validation extension

Cote bloc, validation passe par les extensions `validate(...)` sur `ActivityRepository`, `TransportRepository`, `AccommodationRepository`, `BudgetRepository` (`lib/repositories/validation_extensions.dart`). Single payload `{validation_status: VALIDATED}`. Le handler bloc utilise toujours l'extension, jamais `updateXxx({validation_status: ...})` direct.

## Empty states

Composant unique : `ElegantEmptyState` (icone halotee, animation d'entree subtile, CTA optionnel). Le legacy `EmptyState` a ete supprime. Chaque feature vide (activites, vols, hotels, bagages, depenses, partages) passe par `ElegantEmptyState` avec :

- icone domaine (via la category mapper si applicable),
- titre + body localises,
- CTA optionnel quand l'utilisateur est editor (masque pour viewer).

Quand l'empty state expose un CTA, le FAB / l'icone AppBar est masque (cf. section FAB pattern).

## iOS tab bar et AppShell

`AppShell` (la coquille `GoRouter` qui contient les onglets) cache la `GlassBottomBar` sur les sous-pages : elle n'est visible que sur les routes racine `/home`, `/activity` et `/profile`. Les sous-pages (`/home/:tripId/...`) n'affichent rien en bas — l'utilisateur reste guide par l'`AdaptiveAppBar` et son back button.

Consequence pour le scroll : les sous-pages doivent prevoir un bottom padding adapte au socle iOS (qui occupe ~100 px de safe area + glass bar quand visible). Pattern :

```dart
SliverPadding(
  padding: EdgeInsets.only(
    bottom: AdaptivePlatform.isIOS ? 100 : AppSpacing.space32,
  ),
  sliver: ...,
)
```

Sans ce padding, le dernier item de liste passe sous la glass bar (sur les pages racine) ou sous la home indicator (sur les sous-pages).

## Ce qu'il manque

- **Storybook / catalogue visuel** : aucun outil pour browser les tokens et composants visuellement. Un widget book (`storybook_flutter` ou equivalent) ferait gagner du temps en design review.
- **Dark mode tokens incomplets** : `AppTheme.dark()` existe et le seed bascule sur `secondary`, mais plusieurs couleurs ad-hoc (banners, step accents, review warm grays) n'ont pas de variante dark. La toggle existe en preferences mais reste experimentale.
- **Typography scale doc** : la hierarchie reelle (h1 / h2 / body / caption) n'est pas explicitement nommee — les pages consomment `textTheme.titleLarge` etc. sans guide d'usage clair par contexte.
- **Animation curves** : les durees sont tokenises (`AppAnimationDurations`) mais les courbes (`Curves.easeOutCubic`, `Curves.fastOutSlowIn`, etc.) restent inline. A consolider si la cinetique commence a diverger entre features.
- **Spacing 22 px special** : `space22` existe uniquement pour la marge Plan trip wizard (densite Ive). Le pourquoi est documente inline mais pas dans un guide design — risque de propagation a d'autres ecrans sans intention.
- **AppShadows variantes** : seul `card` est tokenise. Les ombres custom (modal, sheet, glass) restent inline. A elargir si une 2eme variante apparait.
- **Adaptive scaffold incomplet** : `AdaptiveScaffold` ne wrappe pas tous les slots Material (drawer, bottomSheet, persistentFooterButtons). Suffisant pour l'app actuelle mais limite pour de futures pages complexes.
- **Typos `cornerRaidus*`** : trois constantes (`cornerRaidus4`, `cornerRaidus8`, `cornerRaidus16`) portent une typo historique. A renommer en suivant la convention `cornerRadius*` lors d'un cleanup pass.
