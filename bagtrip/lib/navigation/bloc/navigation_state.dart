part of 'navigation_bloc.dart';

enum NavigationTab { home, activity, profile }

final class NavigationState {
  final NavigationTab activeTab;

  const NavigationState({this.activeTab = NavigationTab.home});

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
