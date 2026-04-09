# Dark mode

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

BagTrip supporte trois modes d'affichage : clair, sombre et systeme (par defaut). Le dark mode est implemente via le systeme `ThemeData` de Flutter avec des themes Material et Cupertino distincts. Le basculement est gere par le `SettingsBloc` qui emet un `ThemeMode` consomme par `MaterialApp.router`. Les couleurs sont centralisees dans `AppColors` et `ColorName` (genere), avec des variantes dark explicites pour les cas critiques.

## Architecture du theming

```
SettingsBloc (selectedTheme: 'system' | 'light' | 'dark')
       │
       ▼
MaterialApp.router
  ├── theme:     AppTheme.light()  + cupertinoOverrideTheme: AppTheme.cupertinoLight()
  ├── darkTheme: AppTheme.dark()   + cupertinoOverrideTheme: AppTheme.cupertinoDark()
  └── themeMode: ThemeMode.system / light / dark
```

## SettingsBloc — gestion du choix

**Fichier** : `bagtrip/lib/settings/bloc/settings_bloc.dart`

```dart
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<ChangeTheme>(_onChangeTheme);
  }
  void _onChangeTheme(ChangeTheme event, Emitter<SettingsState> emit) {
    emit(state.copyWith(selectedTheme: event.theme));
  }
}
```

**Etat par defaut** : `selectedTheme = 'system'` (suit le reglage OS).

**Fichier** : `bagtrip/lib/settings/bloc/settings_state.dart`

```dart
final class SettingsState {
  final String selectedTheme;
  const SettingsState({this.selectedTheme = 'system'});
}
```

## Connexion dans main.dart

**Fichier** : `bagtrip/lib/main.dart`

```dart
BlocSelector<SettingsBloc, SettingsState, String>(
  selector: (state) => state.selectedTheme,
  builder: (context, selectedTheme) {
    final ThemeMode themeMode = switch (selectedTheme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    return MaterialApp.router(
      theme: AppTheme.light().copyWith(
        cupertinoOverrideTheme: AppTheme.cupertinoLight(),
      ),
      darkTheme: AppTheme.dark().copyWith(
        cupertinoOverrideTheme: AppTheme.cupertinoDark(),
      ),
      themeMode: themeMode,
    );
  },
)
```

## Themes Material

**Fichier** : `bagtrip/lib/design/app_theme.dart`

### Light theme

```dart
static ThemeData light() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColorName.primary,      // #295F98
      primary: ColorName.primary,
      secondary: ColorName.secondary,    // #35A8B5
      surface: ColorName.primaryLight,   // #EAEFF5
      error: ColorName.error,
    ),
    scaffoldBackgroundColor: PersonalizationColors.gradientStart,  // #F0F4FA
    fontFamily: FontFamily.b612,
  );
  // + customisation textTheme, elevatedButton, card, input
}
```

### Dark theme

```dart
static ThemeData dark() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColorName.secondary,
      primary: ColorName.secondary,      // #35A8B5
      secondary: ColorName.secondary,
      surface: ColorName.primaryDark,    // #1F4772
      error: ColorName.error,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: ColorName.primaryTrueDark,  // #0E2135
    fontFamily: FontFamily.b612,
  );
  // + textTheme avec couleurs claires, hintStyle avec alpha 0.7
}
```

**Differences cles light vs dark** :
- `scaffoldBackgroundColor` : `#F0F4FA` (light) vs `#0E2135` (dark)
- `surface` : `#EAEFF5` vs `#1F4772`
- `titleLarge.color` : `ColorName.primary` vs `ColorName.secondary`
- `bodyMedium.color` : `ColorName.primaryTrueDark` vs `AppColors.surface` (blanc)
- `cardTheme.color` : `ColorName.primarySoftLight` vs `ColorName.primaryDark`
- `hintStyle` : opaque vs `alpha: 0.7`

## Themes Cupertino

**Fichier** : `bagtrip/lib/design/app_theme.dart`

Themes Cupertino pour les composants iOS natifs (pickers, action sheets) :

```dart
static CupertinoThemeData cupertinoLight() {
  return CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: ColorName.secondary,
    scaffoldBackgroundColor: PersonalizationColors.gradientStart,
    barBackgroundColor: PersonalizationColors.gradientStart.withValues(alpha: 0.94),
    textTheme: CupertinoTextThemeData(/* B612, couleurs sombres */),
  );
}

static CupertinoThemeData cupertinoDark() {
  return CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: ColorName.secondary,
    scaffoldBackgroundColor: ColorName.primaryTrueDark,
    barBackgroundColor: ColorName.primaryTrueDark.withValues(alpha: 0.94),
    textTheme: CupertinoTextThemeData(/* B612, couleurs claires */),
  );
}
```

## Couleurs et palette

### ColorName (genere)

**Fichier** : `bagtrip/lib/gen/colors.gen.dart` — genere depuis `assets/color/colors.xml`

Contient les couleurs brutes : `primary` (#295F98), `primaryDark` (#1F4772), `primaryTrueDark` (#0E2135), `secondary` (#35A8B5), `surface` (#FFFFFF), etc.

### AppColors (semantique)

**Fichier** : `bagtrip/lib/design/app_colors.dart`

Couche semantique qui wrappe `ColorName`. Inclut des variantes dark explicites pour les categories budgetaires :

```dart
// Budget category (light)
static const Color categoryFlight = Color(0xFFBBDEFB);
// Budget category (dark)
static const Color categoryFlightDark = Color(0xFF1565C0);
```

### Utilisation dans les composants

Les composants qui adaptent leurs couleurs au dark mode utilisent `Theme.of(context)` :

```dart
// bagtrip/lib/profile/widgets/preferences_section.dart
final isDark = theme.brightness == Brightness.dark;
color: isDark ? ColorName.primaryDark : ColorName.primaryLight,
```

```dart
// Acces au colorScheme
final onSurface = Theme.of(context).colorScheme.onSurface;
```

## UI de selection du theme

**Fichier** : `bagtrip/lib/profile/widgets/preferences_section.dart`

Trois boutons radio visuels (Light / Dark / System) dans la section Preferences du profil :

```dart
Row(children: [
  _buildThemeOption(context, 'light', l10n.themeLight, Icons.light_mode_outlined, ...),
  _buildThemeOption(context, 'dark',  l10n.themeDark,  Icons.dark_mode_outlined, ...),
  _buildThemeOption(context, 'system', l10n.themeSystem, Icons.desktop_windows_outlined, ...),
])
```

Chaque option dispatche `ChangeTheme(themeValue)` au `SettingsBloc`.

## Tests

**Fichier** : `bagtrip/test/blocs/settings_bloc_test.dart`

Couvre :
- Etat initial (`selectedTheme = 'system'`)
- `ChangeTheme('dark')` → emet `selectedTheme = 'dark'`
- `ChangeTheme('light')` → emet `selectedTheme = 'light'`
- Double changement (`dark` → `light`)
- Changement combine theme + langue

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Persistance du theme | Le choix de theme n'est pas persiste. Au redemarrage, il revient a `'system'`. (`bagtrip/lib/settings/bloc/settings_bloc.dart`) | P0 |
| PersonalizationColors sans variante dark | `PersonalizationColors` (`bagtrip/lib/design/personalization_colors.dart`) n'a pas de variantes dark. Le `scaffoldBackgroundColor` du theme light utilise `gradientStart` (#F0F4FA) mais les couleurs de personnalisation restent claires dans le dark mode. | P1 |
| AppColors statiques | `AppColors` n'est pas theme-aware : toutes les couleurs sont des `static const`. Les composants qui utilisent `AppColors.textSecondary` directement (au lieu de `Theme.of(context).colorScheme`) n'adaptent pas leur couleur au dark mode. | P1 |
| Tests widget dark mode | Aucun test widget ne verifie le rendu en dark mode. | P1 |
| Composants avec couleurs en dur | Certains composants pourraient utiliser des couleurs hardcodees (ex: `Colors.white`, `Colors.transparent` dans les bottom sheets) au lieu de couleurs theme-aware. | P2 |
| Transition animee | Le changement de theme est instantane (rebuild complet). Une `AnimatedTheme` ou transition progressive pourrait ameliorer l'UX. | P2 |
| Contraste dark mode | Seule `textSecondaryDark` (4.5:1 sur `primaryTrueDark`) est verifiee par les tests de contraste. Les autres combinaisons de couleurs du dark theme ne sont pas auditee. (`bagtrip/test/accessibility/contrast_audit_test.dart`) | P1 |
