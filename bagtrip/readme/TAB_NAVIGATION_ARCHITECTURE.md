# BagTrip Tab Navigation Architecture

## Overview

A complete tab-based navigation system has been implemented for the BagTrip mobile application with four main tabs: Home, Map, Budget, and Profile.

## Architecture Components

### 1. **Navigation BLoC** (`lib/navigation/bloc/`)

Manages the navigation state and tab switching logic using the BLoC pattern.

#### Files:

- **`navigation_bloc.dart`**: Core BLoC class
  - Handles `NavigationTabChanged` events
  - Maintains the currently active tab state
- **`navigation_event.dart`**: Navigation events
  - `NavigationTabChanged`: Triggered when user selects a different tab
- **`navigation_state.dart`**: Navigation state
  - `NavigationState`: Contains the active tab information
  - `NavigationTab` enum: Defines available tabs (home, map, budget, profile)

### 2. **Pages/Views** (`lib/pages/`)

Separate, self-contained pages for each tab.

#### Files:

- **`home_page.dart`**: Home/Flight search page
  - Refactored from the original `MyHomePage`
  - Uses `HomeFlightBloc` for flight search logic
  - Contains the `HomeView` widget with flight search functionality
- **`map_page.dart`**: Map exploration page
  - Displays destination map interface
  - Placeholder for future map integration
- **`budget_page.dart`**: Budget tracking page
  - Expense tracking interface
  - Budget management features
- **`profile_page.dart`**: User profile page
  - Profile management interface
  - User settings

### 3. **UI Components** (`lib/components/`)

Reusable UI widgets across the application.

#### Files:

- **`bottom_tab_bar.dart`**: Custom bottom navigation bar
  - Displays four tabs with icons and labels
  - Color-coded active/inactive states (teal for active)
  - Responsive and touch-friendly design
  - Uses Material Design icons

### 4. **Main Shell** (`lib/navigation/app_shell.dart`)

Root widget that manages the entire navigation structure.

#### Components:

- **`AppShell`**: Sets up the NavigationBloc provider
- **`AppShellContent`**:
  - Displays the currently active page based on `NavigationState`
  - Contains the `Scaffold` with `bottomNavigationBar`
  - Routes tab selection events to the BLoC

### 5. **Entry Point** (`lib/main.dart`)

Updated to use the new `AppShell` instead of `MyHomePage`.

## Data Flow

```
User taps tab
    ↓
BottomTabBar.onTabChanged()
    ↓
NavigationBloc.add(NavigationTabChanged(tab))
    ↓
NavigationBloc._onTabChanged()
    ↓
emit(state.copyWith(activeTab: tab))
    ↓
BlocBuilder rebuilds with new state
    ↓
AppShellContent displays corresponding page
```

## Folder Structure

```
lib/
├── main.dart                          # App entry point
├── navigation/
│   ├── app_shell.dart                 # Root navigation container
│   └── bloc/
│       ├── navigation_bloc.dart       # BLoC logic
│       ├── navigation_event.dart      # Events
│       └── navigation_state.dart      # States & enums
├── pages/
│   ├── home_page.dart                 # Home/Flight search
│   ├── map_page.dart                  # Map view
│   ├── budget_page.dart               # Budget tracker
│   └── profile_page.dart              # User profile
├── components/
│   └── bottom_tab_bar.dart            # Tab bar widget
├── home/
│   ├── bloc/                          # Flight search BLoC
│   ├── widgets/                       # Flight search widgets
│   └── models/                        # Flight search models
├── service/                           # API services
├── gen/                               # Generated files (colors, fonts)
└── ...
```

## Key Features

✅ **Clean Architecture**: Separation of concerns with dedicated layers
✅ **BLoC Pattern**: Predictable state management
✅ **Reusable Components**: Bottom tab bar can be used across the app
✅ **Scalable**: Easy to add new tabs or features
✅ **Type-Safe**: Strong typing with Dart and enums
✅ **Responsive**: Adapts to different screen sizes
✅ **Material Design**: Uses Flutter's Material Design components

## Dependencies Added

- `equatable: ^2.0.5`: For value equality in BLoC events and states

## Navigation Tabs

| Tab         | Icon            | Description                  |
| ----------- | --------------- | ---------------------------- |
| **Accueil** | home_outlined   | Home page with flight search |
| **Carte**   | map_outlined    | Destination map exploration  |
| **Budget**  | wallet_outlined | Budget tracking and expenses |
| **Profil**  | person_outlined | User profile and settings    |

## Usage

To add a new tab:

1. **Add to enum** in `navigation_state.dart`:

   ```dart
   enum NavigationTab {
     home,
     map,
     budget,
     profile,
     newTab,  // Add here
   }
   ```

2. **Create a page** in `lib/pages/new_page.dart`

3. **Add to switch** in `app_shell.dart`:

   ```dart
   case NavigationTab.newTab:
     return const NewPage();
   ```

4. **Add to tab bar** in `bottom_tab_bar.dart` Row children

## Testing

The BLoC can be tested with:

```dart
test('NavigationBloc emits NavigationState with new tab', () {
  final bloc = NavigationBloc();
  expect(
    bloc.stream,
    emitsInOrder([
      NavigationState(activeTab: NavigationTab.map),
    ]),
  );
  bloc.add(NavigationTabChanged(NavigationTab.map));
});
```

## Future Enhancements

- Deep linking support for direct tab access
- Tab restoration on app restart
- Animation transitions between tabs
- Nested navigation within tabs
- Tab badge notifications (e.g., unread messages)
