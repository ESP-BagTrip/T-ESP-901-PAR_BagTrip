# Accessibilite (a11y)

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

BagTrip integre des mesures d'accessibilite couvrant quatre axes : les labels semantiques pour VoiceOver/TalkBack, les cibles tactiles de 44pt minimum (Apple HIG), le support Dynamic Type jusqu'a 1.5x, et la conformite WCAG AA pour les contrastes de couleurs. Les annotations `Semantics` sont posees sur les composants interactifs cles (cards, images, boutons), et une suite de tests dediee (`test/accessibility/`) verifie ces garanties.

## Semantic labels (VoiceOver / TalkBack)

### OptimizedImage

**Fichier** : `bagtrip/lib/components/optimized_image.dart`

Chaque image est encapsulee dans un `Semantics(image: true)` avec un label optionnel. Quand aucun `semanticLabel` n'est fourni, le label est vide mais l'image reste annoncee comme telle.

```dart
@override
Widget build(BuildContext context) {
  return Semantics(
    image: true,
    label: semanticLabel ?? '',
    excludeSemantics: true,
    child: CachedNetworkImage(/* ... */),
  );
}
```

### TripCard

**Fichier** : `bagtrip/lib/trips/widgets/trip_card.dart`

Les cards de voyage utilisent `Semantics(excludeSemantics: true)` avec un label compose qui decrit le titre, la destination et les dates.

### TimelineActivityCard

**Fichier** : `bagtrip/lib/trip_detail/widgets/timeline_activity_card.dart`

Chaque carte d'activite a un `Semantics` de niveau superieur qui combine titre, horaire, lieu et statut. Les boutons d'action internes (Valider, Rejeter) ont leurs propres annotations `Semantics(button: true)`.

```dart
final card = Semantics(
  label: '${activity.title}, ${_timeLabel()}, ...',
  excludeSemantics: true,
  child: /* contenu de la carte */,
);
```

### ActivityCard

**Fichier** : `bagtrip/lib/activities/widgets/activity_card.dart`

Label semantique localise via `l10n.activityCardSemanticLabel(title, time, location, status)`.

```dart
final semanticCard = Semantics(
  label: l10n.activityCardSemanticLabel(
    activity.title,
    semanticTime,
    activity.location ?? '',
    semanticStatus,
  ),
  excludeSemantics: true,
  child: cardContent,
);
```

### ElegantEmptyState

**Fichier** : `bagtrip/lib/components/elegant_empty_state.dart`

Utilise `MergeSemantics` pour fusionner icone + titre + sous-titre en un seul noeud VoiceOver. Le halo decoratif est exclu via `ExcludeSemantics`.

```dart
MergeSemantics(
  child: Column(children: [
    ExcludeSemantics(child: /* halo decoratif */),
    Text(title),
    if (subtitle != null) Text(subtitle!),
  ]),
)
```

### BottomTabBar

**Fichier** : `bagtrip/lib/components/bottom_tab_bar.dart`

Sur iOS (GlassBottomBar), la barre de navigation a un `Semantics` avec label dynamique qui inclut le nombre de notifications.

```dart
Semantics(
  label: activityBadgeCount > 0
      ? l10n.tabActivityWithBadge(activityBadgeCount)
      : null,
  child: bar,
)
```

## Touch targets (>= 44pt)

Tous les elements interactifs doivent respecter la taille minimale de 44pt (Apple HIG) :

- **ActionChip** : `ConstrainedBox(constraints: BoxConstraints(minHeight: 44))` dans `timeline_activity_card.dart`
- **IconButton** : taille par defaut Flutter >= 48px, conforme
- **TextButton** : `minimumSize: Size.fromHeight(42)` dans le theme (`app_theme.dart`), augmente par le padding

Le theme global (`AppTheme.light()`) definit :
```dart
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(42),
    padding: AppSpacing.allEdgeInsetSpace16,
  ),
),
```

## Dynamic Type (1.5x)

L'application supporte les tailles de texte dynamiques jusqu'a 1.5x sans overflow :

- **ConstrainedBox avec minHeight** : les composants critiques (trip cards, day chips, empty states) utilisent `ConstrainedBox(constraints: BoxConstraints(minHeight: X))` au lieu de hauteurs fixes, permettant l'expansion du texte
- **SingleChildScrollView** : les contenus qui pourraient deborder sont encapsules dans des ScrollView
- **Pas de ClipRect** agressif sur les textes

## Contraste WCAG AA

**Fichier** : `bagtrip/lib/design/app_colors.dart`

Des couleurs de texte pre-calculees avec des ratios de contraste documentes :

```dart
static const Color textSecondary = Color(0xFF5B6A7B);   // 5.2:1 sur blanc
static const Color textTertiary = Color(0xFF4A5568);     // 6.3:1 sur blanc
static const Color textDisabled = Color(0xFF6B7280);     // 4.6:1 sur blanc (minimum AA)
static const Color textSecondaryDark = Color(0xFFB0BEC5); // 4.5:1 sur #0E2135
```

Le projet n'utilise jamais de couleurs Material brutes (`Colors.blue`, `Colors.red`, etc.) dans le code source — tout passe par `AppColors.*` ou `ColorName.*`.

## Suite de tests accessibilite

**Repertoire** : `bagtrip/test/accessibility/`

### Helpers

**Fichier** : `test/accessibility/a11y_test_helpers.dart`

Fournit :
- `buildTestableWidget(child, {textScale})` — wrapper MaterialApp avec l10n et support textScale
- `relativeLuminance(Color)` — calcul WCAG 2.1 de luminance relative
- `contrastRatio(Color fg, Color bg)` — ratio de contraste WCAG
- `expectMinimumTouchTargets(tester, {minSize})` — verification des tailles tactiles

### Tests par axe

| Fichier | Axe | Nombre de tests |
|---------|-----|-----------------|
| `test/accessibility/semantic_labels_test.dart` | AX1 — Labels semantiques (OptimizedImage, ElegantEmptyState) | 4 |
| `test/accessibility/touch_targets_test.dart` | AX2 — Touch targets >= 44pt (ActionChip, TextButton, IconButton) | 3 |
| `test/accessibility/dynamic_type_test.dart` | AX3 — Dynamic Type 1.5x (ElegantEmptyState, ConstrainedBox, DayChip) | 3 |
| `test/accessibility/contrast_audit_test.dart` | AX4 — Contraste WCAG AA (textSecondary, textTertiary, textDisabled, dark, warning) | 7 |

**Total** : 17 tests d'accessibilite.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Semantics sur les formulaires | Les champs de saisie (`AdaptiveTextField`, formulaires de vol, budget) n'ont pas de `Semantics(textField: true, label: ...)` explicites. VoiceOver peut les decrire generiquement. | P1 |
| Traverse order | Pas de `Semantics(sortKey: OrdinalSortKey(...))` pour controler l'ordre de lecture VoiceOver dans les ecrans complexes (trip detail, timeline). | P1 |
| Labels sur les bottom sheets | Les bottom sheets n'ont pas de `Semantics(label: ...)` pour annoncer leur titre a l'ouverture. | P1 |
| Test a11y des composants adaptatifs | Les composants de `lib/components/adaptive/` (AdaptiveButton, AdaptiveDialog, etc.) n'ont pas de tests d'accessibilite dedies. | P2 |
| Support au-dela de 1.5x | Les tests Dynamic Type ne couvrent que 1.5x. iOS permet jusqu'a ~3.5x (accessibilite). Certains layouts pourraient casser au-dela de 2x. | P2 |
| Audit automatise exhaustif | Pas d'utilisation de `flutter test --accessibility` ou d'outils comme `accessibility_tools` pour un audit global. Seuls quelques composants sont testes manuellement. | P2 |
| Annotations semantiques sur le dark mode | Pas de verification que les contrastes restent >= 4.5:1 dans le theme dark (seul `textSecondaryDark` est teste sur `primaryTrueDark`). | P1 |
| Focus management | Pas de gestion explicite du focus pour la navigation clavier/switch control dans les formulaires multi-etapes (PlanTrip flow). | P2 |
