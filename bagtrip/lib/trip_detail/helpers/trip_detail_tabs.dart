/// Chip indices for [TripDetailView] [TabController] (owner layout).
const tripDetailActivitiesTabIndex = 3;

/// Deep-linkable trip-detail panel selected via [TripHomeRoute.tab].
enum TripDetailTab { activities }

extension TripDetailTabQuery on TripDetailTab {
  int get tabIndex => switch (this) {
    TripDetailTab.activities => tripDetailActivitiesTabIndex,
  };

  static TripDetailTab? fromQuery(String? value) {
    if (value == null) return null;
    for (final tab in TripDetailTab.values) {
      if (tab.name == value) return tab;
    }
    return null;
  }
}
