part of 'navigation_bloc.dart';

enum NavigationTab { explorer, trips, activity, profile }

class NavigationState {
  final NavigationTab activeTab;

  const NavigationState({this.activeTab = NavigationTab.trips});

  NavigationState copyWith({NavigationTab? activeTab}) {
    return NavigationState(activeTab: activeTab ?? this.activeTab);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationState &&
          runtimeType == other.runtimeType &&
          activeTab == other.activeTab;

  @override
  int get hashCode => activeTab.hashCode;
}
