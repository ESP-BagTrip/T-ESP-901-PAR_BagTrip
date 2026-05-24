# Dark mode

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip supporte trois modes d'affichage : `light`, `dark` et `system` (defaut). Le
basculement passe par un unique levier : `SettingsBloc.selectedTheme` (string `'system'`,
`'light'`, `'dark'`) est lu dans `main.dart`, traduit en `ThemeMode`, et consomme par
`MaterialApp.router` qui choisit entre `theme:` et `darkTheme:`. Les deux themes sont
declares dans `AppTheme` (Material + Cupertino) et puisent dans la palette generee
`ColorName` plus la couche semantique `AppColors`. Le choix est persiste via
`SettingsStorage` et restaure au demarrage par `LoadSettings`.

Chaine complete :

```
SettingsStorage (shared prefs)
    -> SettingsBloc.selectedTheme : 'system' | 'light' | 'dark'
    -> main.dart BlocBuilder<SettingsBloc, SettingsState>
    -> ThemeMode.system / light / dark
    -> MaterialApp.router(theme:, darkTheme:, themeMode:)
    -> AppTheme.light() + cupertinoLight() / AppTheme.dark() + cupertinoDark()
```

## ThemeData

Fichier : `bagtrip/lib/design/app_theme.dart`. Classe statique `AppTheme` avec quatre
constructeurs : `light()`, `dark()`, `cupertinoLight()`, `cupertinoDark()`.

### Light

Base : `ColorScheme.fromSeed(seedColor: ColorName.primary)`, `useMaterial3: true`,
`scaffoldBackgroundColor: PersonalizationColors.gradientStart` (#F0F4FA),
`fontFamily: FontFamily.b612`. Surcharges :

- `textTheme.titleLarge.color` = `ColorName.primary` (#295F98).
- `textTheme.titleMedium.color` / `bodyMedium.color` = `ColorName.primaryTrueDark`.
- `elevatedButtonTheme` : fond `ColorName.secondary` (#35A8B5), texte `AppColors.surface`,
  radius `AppRadius.large16`, hauteur `AppSize.height42`.
- `cardTheme.color` = `ColorName.primarySoftLight`.
- `inputDecorationTheme.hintStyle.color` = `ColorName.primary` (opaque).

### Dark

Base : `ColorScheme.fromSeed(seedColor: ColorName.secondary, brightness: Brightness.dark)`,
`surface: ColorName.primaryDark` (#1F4772), `scaffoldBackgroundColor:
ColorName.primaryTrueDark` (#0E2135). Surcharges :

- `textTheme.titleLarge.color` = `ColorName.secondary` (le secondary devient l'accent
  visuel principal en dark).
- `textTheme.titleMedium.color` / `bodyMedium.color` / `labelLarge.color` =
  `AppColors.surface` (blanc).
- `elevatedButtonTheme` : meme style que light (secondary fond + blanc), garantit la
  coherence du CTA principal entre les deux modes.
- `cardTheme.color` = `ColorName.primaryDark`.
- `inputDecorationTheme.hintStyle.color` = `ColorName.surface.withValues(alpha: 0.7)`.

### Cupertino

`cupertinoLight()` et `cupertinoDark()` sont passes via `ThemeData.copyWith(
cupertinoOverrideTheme: ...)` dans `main.dart`. Ils alignent `primaryColor`,
`scaffoldBackgroundColor`, `barBackgroundColor` (alpha 0.94 pour les blurs) et un
`CupertinoTextThemeData` complet (`textStyle`, `navTitleTextStyle`,
`navLargeTitleTextStyle`) en B612 sur la bonne couleur de texte. Indispensable pour les
action sheets, pickers, dialogs Cupertino qui ignorent `ThemeData` Material.

## Couleurs semantiques

Fichier : `bagtrip/lib/design/app_colors.dart`. `AppColors` est une couche semantique
au-dessus de `ColorName` (genere par flutter_gen depuis `assets/color/colors.xml`).
Regles :

- Surfaces : `surface`, `surfaceLight`, `surfaceDark`, `surfaceVariant`.
- Texte : `onSurface`, `onSurfaceAlt`, `onPrimary`, `hint`, plus les tokens accessibles
  pre-calcules `textSecondary` (5.2:1 sur blanc), `textTertiary` (6.3:1), `textDisabled`
  (4.6:1 - minimum AA), `textSecondaryDark` (4.5:1 sur #0E2135).
- Resolvers brightness-aware (statiques, prennent `Brightness b`) :
  - `textSecondaryOf(b)` : `textSecondaryDark` en dark, `textSecondary` en light.
  - Budget categories : `categoryFlightOf(b)`, `categoryAccommodationOf(b)`,
    `categoryFoodOf(b)`, `categoryActivityOf(b)`, `categoryTransportOf(b)`,
    `categoryOtherOf(b)` - pastels en light, shade 800 en dark.

Les composants qui s'adaptent au mode lisent `Theme.of(context).brightness` puis passent
l'enum au resolver, ou utilisent directement `Theme.of(context).colorScheme.*`. Exemple
type :

```dart
final brightness = Theme.of(context).brightness;
final bg = AppColors.categoryFlightOf(brightness);
final secondaryText = AppColors.textSecondaryOf(brightness);
```

Les constantes restantes (alert banners, review step neutrals, AI chips, budget ring
chart) sont light-only - non couvertes par le dark mode aujourd'hui (cf. `Ce qu'il
manque`).

## ThemeMode et persistence

Fichier : `bagtrip/lib/settings/bloc/settings_bloc.dart`. `SettingsBloc` gere trois
events : `LoadSettings`, `ChangeTheme`, `ChangeLanguage`.

```dart
SettingsBloc({SettingsStorage? settingsStorage, bool autoLoad = true})
  : _storage = settingsStorage ?? getIt<SettingsStorage>(),
    super(const SettingsState()) {
  on<LoadSettings>(_onLoadSettings);
  on<ChangeTheme>(_onChangeTheme);
  on<ChangeLanguage>(_onChangeLanguage);
  if (autoLoad) add(LoadSettings());
}
```

`LoadSettings` lit `SettingsStorage.getTheme()` et restitue `'system'` en fallback.
`ChangeTheme` emet immediatement le nouvel etat puis ecrit dans le storage
(`await _storage.setTheme(event.theme)`) - emit-then-persist pour que l'UI bascule sans
attendre l'I/O. `autoLoad: true` lance le `LoadSettings` initial des la construction du
bloc, ce qui restaure le choix utilisateur au demarrage.

Cote `main.dart`, le `BlocBuilder<SettingsBloc, SettingsState>` enveloppe
`MaterialApp.router` et mappe la string vers `ThemeMode` :

```dart
final ThemeMode themeMode = switch (settingsState.selectedTheme) {
  'dark' => ThemeMode.dark,
  'light' => ThemeMode.light,
  _ => ThemeMode.system,
};
return MaterialApp.router(
  theme: AppTheme.light().copyWith(cupertinoOverrideTheme: AppTheme.cupertinoLight()),
  darkTheme: AppTheme.dark().copyWith(cupertinoOverrideTheme: AppTheme.cupertinoDark()),
  themeMode: themeMode,
  ...
);
```

`ThemeMode.system` laisse Flutter suivre `MediaQuery.platformBrightnessOf(context)`.

## Toggle Settings

Fichier : `bagtrip/lib/profile/view/settings_page.dart`. La page est minimaliste : un
`Scaffold` avec `AppBar` titre `l10n.settingsTitle` et un `SingleChildScrollView` qui
delegue tout le contenu a `PreferencesSection`
(`bagtrip/lib/profile/widgets/preferences_section.dart`).

`PreferencesSection` affiche trois boutons radio visuels (Light / Dark / System) en
`Row`, chacun rendu par `_buildThemeOption(context, themeValue, label, icon, ...)`.
Chaque option dispatche `ChangeTheme(themeValue)` au `SettingsBloc` recupere par
`context.read<SettingsBloc>()`. Le bouton actif est determine par
`state.selectedTheme == themeValue` et utilise `ColorName.primaryDark` /
`ColorName.primaryLight` selon la brightness courante - les options sont elles-memes
theme-aware.

La page propose aussi la selection de langue (`ChangeLanguage`), partage le meme bloc et
le meme pattern.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| `PersonalizationColors` sans variante dark | Les gradients de personnalisation et `scaffoldBackgroundColor` light s'appuient sur `PersonalizationColors.gradientStart`, sans equivalent dark - les ecrans qui pochent ces gradients restent clairs meme en dark mode. | P1 |
| `AppColors` partiellement statique | Les constantes light-only (alert banners, review step neutrals, AI chips, budget ring chart) ne sont pas couvertes par des resolvers `*Of(Brightness)`. Composants concernes apparaissent identiques en dark, parfois illisibles. | P1 |
| Audit contraste dark incomplet | Seul `textSecondaryDark` (4.5:1 sur `primaryTrueDark`) est verifie par `test/accessibility/contrast_audit_test.dart`. Les autres combinaisons du dark theme (titres, hints alpha 0.7, cards) ne sont pas auditees. | P1 |
| Tests widget dark mode | Aucun test widget ne pump l'app avec `themeMode: ThemeMode.dark` pour valider le rendu des composants critiques (`AdaptiveButton`, `ItemStatusChip`, bottom sheets). | P1 |
| Couleurs hardcodees dans les bottom sheets | Le pattern de sheet standard fixe `backgroundColor: Colors.transparent` + `color: Colors.white` sur le container - blanc dur en dark mode. A remplacer par `Theme.of(context).colorScheme.surface`. | P2 |
| Transition animee de theme | Le changement est instantane (rebuild complet). Un `AnimatedTheme` ou une transition crossfade ameliorerait l'UX au toggle. | P2 |
| Pas de preview dark dans le wizard de personnalisation | Le step de personnalisation ne propose pas de preview du rendu dark, l'utilisateur ne voit le resultat qu'apres validation. | P3 |
