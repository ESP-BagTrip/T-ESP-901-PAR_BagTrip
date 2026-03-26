# Design System Mobile BagTrip (Flutter)

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

Le design system BagTrip est organise en couches : des **tokens** primitifs (spacing, radius, couleurs), un **theme** Material3 + Cupertino, des **composants adaptatifs** (Android/iOS), et des **widgets design** reutilisables. Toutes les valeurs visuelles sont centralisees -- aucun hex brut ni magic number ne doit apparaitre dans les features. La police unique est **B612** (`FontFamily.b612`).

## Tokens

### Spacing -- `lib/design/tokens.dart`

Systeme base 4/8px via `AppSpacing` :

| Token | Valeur | Usage typique |
|-------|--------|---------------|
| `space4` | 4px | Micro espacement, gap entre icone et texte |
| `space8` | 8px | Espacement compact, padding chips |
| `space12` | 12px | Padding interne cartes |
| `space16` | 16px | Padding standard sections |
| `space24` | 24px | Marges externes, padding modals |
| `space32` | 32px | Sections larges |
| `space40` | 40px | Grandes separations |
| `space48` | 48px | Bottom padding ecrans |
| `space56` | 56px | Espacement exceptionnel |

EdgeInsets pre-calcules disponibles : `allEdgeInsetSpace*`, `horizontalSpace*`, `verticalSpace*`, `onlyTopSpace*`, `onlyBottomSpace*`, etc.

```dart
// Utilisation
Padding(padding: AppSpacing.allEdgeInsetSpace16, child: content)
const SizedBox(height: AppSpacing.space24)
```

### Tailles fixes -- `AppSize`

```dart
class AppSize {
  static const double height42 = 42.0;   // Hauteur boutons
  static const double width42 = 42.0;
  static const double iconSizeHeight24 = 24.0;
  static const double boxSize8 = 8.0;
  static const double boxSize16 = 16.0;
}
```

### Radius -- `AppRadius`

| Token | Valeur | Usage |
|-------|--------|-------|
| `small4` | 4px | Tags, badges |
| `medium8` | 8px | Chips, petits containers |
| `large16` | 16px | Cartes, bottom sheets |
| `large20` | 20px | Panels glass, modals |
| `large24` | 24px | Grands containers |
| `large28` | 28px | Containers speciaux |
| `large32` | 32px | Containers plein ecran |
| `pill` | 999px | Boutons arrondis, badges |

```dart
// Utilisation
Container(
  decoration: BoxDecoration(borderRadius: AppRadius.large16),
)
```

Note : les constantes `cornerRaidus4` et `cornerRaidus8` contiennent un typo (`Raidus` au lieu de `Radius`) -- les variantes `cornerRadius20/24/28/32` sont correctes.

### Couleurs

#### Palette generee -- `lib/gen/colors.gen.dart`

Generee par FlutterGen depuis `assets/color/colors.xml`. Contient les couleurs brutes : `ColorName.primary` (#295F98), `ColorName.secondary` (#35A8B5), `ColorName.surface` (#FFFFFF), etc. **Ne jamais utiliser directement** dans les features.

#### Couche semantique -- `lib/design/app_colors.dart`

Wrapper semantique autour de `ColorName`. A utiliser partout :

```dart
class AppColors {
  // Surfaces
  static const Color surface = ColorName.surface;
  static const Color surfaceLight = ColorName.surfaceLight;
  static const Color surfaceDark = ColorName.surfaceDark;

  // Texte
  static const Color onSurface = ColorName.primaryTrueDark;
  static const Color textSecondary = Color(0xFF5B6A7B);   // 5.2:1 contrast
  static const Color textTertiary = Color(0xFF4A5568);     // 6.3:1 contrast
  static const Color textDisabled = Color(0xFF6B7280);     // 4.6:1 AA minimum

  // Brand
  static const Color primary = ColorName.primary;          // #295F98
  static const Color secondary = ColorName.secondary;      // #35A8B5

  // Status
  static const Color success = ColorName.success;          // #4CAF50
  static const Color warning = ColorName.warning;          // #FF9800
  static const Color error = ColorName.error;              // #F44336
  static const Color info = ColorName.info;                // #2196F3

  // Budget categories (light + dark variants)
  static const Color categoryFlight = Color(0xFFBBDEFB);
  static const Color categoryAccommodation = Color(0xFFE1BEE7);
  // ...

  // Shadows pre-calcules
  static final Color shadowLight = Color(0xFF000000).withValues(alpha: 0.06);
  static final Color shadowSubtle = Color(0xFF000000).withValues(alpha: 0.04);
}
```

#### Couleurs de personnalisation -- `lib/design/personalization_colors.dart`

Palette premium pour les flows onboarding/personnalisation :

```dart
class PersonalizationColors {
  // Gradients background (bleu -> violet doux)
  static const List<Color> backgroundGradient = [gradientStart, gradientMid, gradientEnd];
  static const List<Color> accentGradient = [accentBlue, accentViolet];

  // Glass / frosted surfaces
  static const Color surfaceGlass = Color(0x1AFFFFFF);
  static const Color surfaceGlassBorder = Color(0x26FFFFFF);

  // Card states
  static const Color cardBorderSelected = Color(0xFF5B7CFD);
  static const Color chipSelected = Color(0x265B7CFD);
}
```

### Police

Police unique **B612** enregistree dans `lib/gen/fonts.gen.dart` :

```dart
class FontFamily {
  static const String b612 = 'B612';
}
```

Appliquee globalement via `fontFamily: FontFamily.b612` dans les ThemeData light et dark.

## Theme -- `lib/design/app_theme.dart`

4 themes exposes par `AppTheme` :

| Methode | Usage |
|---------|-------|
| `AppTheme.light()` | ThemeData Material3 light |
| `AppTheme.dark()` | ThemeData Material3 dark |
| `AppTheme.cupertinoLight()` | CupertinoThemeData light |
| `AppTheme.cupertinoDark()` | CupertinoThemeData dark |

Le theme Cupertino est injecte via `cupertinoOverrideTheme` dans `main.dart` :

```dart
MaterialApp.router(
  theme: AppTheme.light().copyWith(
    cupertinoOverrideTheme: AppTheme.cupertinoLight(),
  ),
  darkTheme: AppTheme.dark().copyWith(
    cupertinoOverrideTheme: AppTheme.cupertinoDark(),
  ),
)
```

Configurations notables du theme :
- Boutons `ElevatedButton` : fond `secondary` (#35A8B5), hauteur 42px, radius 16px, elevation 0.
- Cards : elevation 0, couleur `primarySoftLight`, radius 16px.
- Scaffold background : `PersonalizationColors.gradientStart` (#F0F4FA) en light, `primaryTrueDark` (#0E2135) en dark.

## Scroll Behavior adaptatif

`_AdaptiveScrollBehavior` dans `main.dart` ajuste la physique de scroll :
- **iOS** : `BouncingScrollPhysics` (rebond natif)
- **Android** : `ClampingScrollPhysics` + overscroll glow

## Detection de plateforme -- `lib/core/platform/adaptive_platform.dart`

```dart
abstract class AdaptivePlatform {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
  static T select<T>({required T material, required T cupertino}) {
    return isIOS ? cupertino : material;
  }
}
```

**Regle stricte** : toujours utiliser `AdaptivePlatform.isIOS` et jamais `Platform.isIOS` directement.

## Composants adaptatifs -- `lib/components/adaptive/`

11 composants qui rendent automatiquement Material sur Android et Cupertino sur iOS :

### AdaptiveScaffold

`Scaffold` (Android) / `CupertinoPageScaffold` (iOS) avec SafeArea automatique sur iOS.

### AdaptiveAppBar

Factory statique qui retourne un `AppBar` Material ou un `GlassAppBar` (liquid_glass_widgets) selon la plateforme :

```dart
AdaptiveAppBar.build(
  context: context,
  title: 'Mes voyages',
  actions: [IconButton(...)],
)
```

Sur iOS, le `GlassAppBar` utilise le shader Liquid Glass pour l'effet verre natif iOS 26.

### AdaptiveButton

`ElevatedButton` / `CupertinoButton.filled`. Supporte `isLoading` avec indicateur adaptatif.

### AdaptiveTextField

`TextFormField` / `CupertinoTextField`. Background gris arrondi sur iOS, `OutlineInputBorder` sur Android.

### AdaptiveDialog

```dart
showAdaptiveAlertDialog(
  context: context,
  title: 'Supprimer ?',
  confirmLabel: 'Supprimer',
  cancelLabel: 'Annuler',
  isDestructive: true,
  onConfirm: () => bloc.add(DeleteTrip(tripId)),
);
```

Rend `CupertinoAlertDialog` sur iOS, `AlertDialog` sur Android.

### AdaptiveActionSheet

`CupertinoActionSheet` (iOS) / `showModalBottomSheet` avec handle bar (Android).

### AdaptiveEditDialog

Dialog avec champ texte. Retourne la nouvelle valeur ou `null` si annule.

### AdaptiveDatePicker / AdaptiveTimePicker

Calendrier Material (Android) / roue CupertinoDatePicker (iOS) avec barre Cancel/Done.

### AdaptiveIndicator

`CircularProgressIndicator.adaptive()` -- spinner natif par plateforme.

### AdaptiveContextMenu

`CupertinoContextMenu` sur iOS (long press -> menu d'actions avec preview). Passe-plat sur Android.

```dart
AdaptiveContextMenu(
  actions: [
    AdaptiveContextAction(
      label: 'Modifier',
      icon: CupertinoIcons.pencil,
      onPressed: () => _edit(),
    ),
    AdaptiveContextAction(
      label: 'Supprimer',
      icon: CupertinoIcons.trash,
      onPressed: () => _delete(),
      isDestructive: true,
    ),
  ],
  child: TripCard(trip: trip),
)
```

## Animations -- `lib/design/app_animations.dart`

Constantes centralisees nommees par intention :

| Token | Valeur | Usage |
|-------|--------|-------|
| `springCurve` | `Curves.easeOutBack` | Emphasis, rebond subtil |
| `standardCurve` | `Curves.easeOutCubic` | Transitions standard, fades |
| `staggerDelay` | 80ms | Delai entre items de liste |
| `cardTransition` | 350ms | Hero transitions, cartes |
| `microInteraction` | 200ms | Feedback tap, changement couleur |
| `wizardTransition` | 300ms | Transitions entre etapes |
| `fadeIn` | 400ms | Empty states, halo |
| `pressFeedback` | 150ms | Scale/press rapide |

### StaggeredFadeIn -- `lib/components/staggered_fade_in.dart`

Widget d'animation qui fait apparaitre les elements de liste avec un delai indexe. Chaque item fade-in + slide-up :

```dart
StaggeredFadeIn(
  index: i,
  baseDelay: AppAnimations.staggerDelay,
  child: ActivityCard(activity: activities[i]),
)
```

## Haptics -- `lib/design/app_haptics.dart`

Feedback haptique centralise, **iOS uniquement** (Android gere au niveau OS) :

| Methode | Intensite | Usage |
|---------|-----------|-------|
| `AppHaptics.light()` | Light | Selection, toggle, tap chip |
| `AppHaptics.medium()` | Medium | Press bouton, selection carte |
| `AppHaptics.success()` | Heavy | Trip creee, etape completee |
| `AppHaptics.error()` | Vibrate | Echec validation, erreur reseau |

```dart
GestureDetector(
  onTap: () {
    AppHaptics.medium();
    onTap();
  },
  child: card,
)
```

## Widgets Design reutilisables

### `lib/components/`

| Widget | Description |
|--------|-------------|
| **ElegantEmptyState** | Etat vide avec halo gradient, icone, titre, CTA. Animation fade-in + slide-up. Remplace le legacy `EmptyState`. |
| **ErrorView** | Ecran d'erreur avec icone, message, bouton retry. |
| **LoadingView** | Spinner adaptatif + message optionnel. |
| **PaginatedList** | ListView avec scroll infini, support groupement, pull-to-refresh. |
| **OfflineBanner** | Banniere jaune animee en haut de l'ecran quand offline. |
| **BottomTabBar** | Tab bar adaptative : `GlassBottomBar` (iOS) / `NavigationBar` (Android). Badge sur l'onglet Activity. |
| **OptimizedImage** | Image reseau cachee via `CachedNetworkImage` avec shimmer loading et placeholder gradient. Deux presets : `.tripCover` (800px) et `.activityImage` (400px). |
| **AppSnackBar** | Snackbar overlay avec 3 types (error/success/info). Toast frosted glass sur iOS, Material elevation sur Android. |
| **SummaryDateCard** | Carte date pour les ecrans recap : icone calendrier, label, date formatee. |
| **CustomCalendarPicker** | Calendrier modal avec navigation par mois, selection range, highlight today. |

### `lib/design/widgets/`

| Widget | Description |
|--------|-------------|
| **GlassPanel** | Panel frosted glass. iOS : `LiquidGlassContainer` (Liquid Glass shader). Android : `BackdropFilter` avec blur 12px. |
| **PrimaryButton** | Bouton pleine largeur adaptatif (CupertinoButton.filled / ElevatedButton) avec loading state. |
| **StatusBadge** | Badge de statut avec 5 types (pending, confirmed, forecasted, active, completed). Couleur automatique. |
| **StepHeader** | Resume compact des etapes wizard, expandable (collapsed: icones inline / expanded: detail complet). |
| **PremiumStepIndicator** | Indicateur de progression en points (dot actif elargi 20px, inactifs 8px) avec animation. |
| **PremiumCtaButton** | CTA premium avec gradient bleu->violet, ombre coloree, animation scale au press. |
| **AiSuggestionCard** | Carte suggestion IA avec image, destination, match reason, badges, info chips (duree/prix). |
| **StreamingChecklist** | Checklist animee pour visualiser la progression SSE. Stagger fade-in + cross-fade pending/done + haptic sur completion. |
| **BudgetChipSelector** | Grille 2x2 de chips budget avec emoji, label, range. Selection unique avec animation. |
| **DestinationCarousel** | Carousel horizontal page par page avec effet scale sur les cartes adjacentes + indicateurs dots. |
| **FlexibleDatePicker** | Picker 3 modes (exact/mois/flexible) avec segment control adaptatif. |
| **PremiumPaywall** | Bottom sheet premium avec liste de features et CTA upgrade Stripe. |

## SnackBar System

Le systeme de snackbar est base sur un `InheritedWidget` overlay (`lib/components/snack_bar_scope.dart`) :

1. `SnackBarScope` est wrape autour de l'app dans `main.dart` via `MaterialApp.router(builder:)`.
2. Les snackbars sont des `OverlayEntry` positionnees en haut de l'ecran avec SafeArea.
3. Animation : slide-down elastique + fade-in (600ms entree, 400ms sortie, 4s affichage).
4. Un seul snackbar visible a la fois (le precedent est `remove()`).

```dart
AppSnackBar.showSuccess(context, message: 'Voyage cree !');
AppSnackBar.showError(context, message: error.toUserFriendlyMessage());
```

## Assets generes -- `lib/gen/`

| Fichier | Contenu | Regeneration |
|---------|---------|--------------|
| `colors.gen.dart` | `ColorName.*` (25 couleurs) | `build_runner` apres modif `assets/color/colors.xml` |
| `fonts.gen.dart` | `FontFamily.b612` | `build_runner` apres ajout de polices |
| `assets.gen.dart` | `Assets.images.*` (AppIcon SVG, flight, hotel, etc.) | `build_runner` apres ajout d'images |

## Pattern FAB adaptatif

Convention stricte pour le bouton d'ajout :

```dart
// Android : FAB dans le Scaffold
floatingActionButton: canEdit && !AdaptivePlatform.isIOS
    ? FloatingActionButton.extended(
        onPressed: _showForm,
        label: Text(l10n.addActivity),
        icon: const Icon(Icons.add),
      )
    : null,

// iOS : IconButton dans l'AppBar
appBar: AppBar(
  actions: [
    if (canEdit && AdaptivePlatform.isIOS)
      IconButton(
        icon: const Icon(CupertinoIcons.add),
        onPressed: _showForm,
      ),
  ],
),
```

**Regle** : jamais de FAB + CTA empty state en meme temps. Si la liste est vide, CTA dans l'empty state seulement.

## Pattern Bottom Sheet

Toute bottom sheet doit suivre cette decoration :

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
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 12),
      Center(child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      )),
      // ... content
    ]),
  ),
);
```

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Typo dans AppRadius | `cornerRaidus4` et `cornerRaidus8` contiennent un typo (`Raidus` au lieu de `Radius`) dans `lib/design/tokens.dart` | P2 |
| Pas de dark mode pour AppColors semantiques | `AppColors` definit les couleurs statiquement sans variante dark -- les couleurs comme `textSecondary`, `textTertiary`, `categoryFlight` ne s'adaptent pas au dark mode | P1 |
| PremiumPaywall hardcode en francais | `lib/design/widgets/premium_paywall.dart:82` contient `'Passez a Premium'` en dur au lieu de passer par l10n | P1 |
| AdaptiveIndicator ignore ses parametres | `lib/components/adaptive/adaptive_indicator.dart` accepte `radius` et `color` mais `radius` n'est pas utilise dans le build, et `color` est passe via `valueColor` qui ne fonctionne pas avec le constructeur `.adaptive()` | P2 |
| Pas de dark mode pour PersonalizationColors | `lib/design/personalization_colors.dart` ne definit que des couleurs light -- le flow personnalisation sera illisible en dark mode | P1 |
| GlassPanel Android sans test dark mode | `lib/design/widgets/glass_panel.dart` utilise `PersonalizationColors.surfaceGlass` (blanc translucide) qui sera invisible sur fond dark | P2 |
| DestinationCarousel hauteur fixe | `lib/design/widgets/destination_carousel.dart:62` utilise `height: 320` en dur au lieu d'un token ou d'une valeur responsive | P2 |
| CustomCalendarPicker pas adaptatif | `lib/components/custom_calendar_picker.dart` utilise un Dialog Material brut sur toutes les plateformes sans variante Cupertino | P2 |
| Pas de composant AdaptiveSwitch | Le catalogue adaptatif ne contient pas de switch/toggle -- les features utilisant des toggles doivent gerer manuellement Material/Cupertino | P2 |
