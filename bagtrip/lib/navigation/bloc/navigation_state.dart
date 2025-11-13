part of 'navigation_bloc.dart';

enum NavigationTab { home, map, budget, profile }

class NavigationState extends Equatable {
  final NavigationTab activeTab;

  const NavigationState({this.activeTab = NavigationTab.home});

  NavigationState copyWith({NavigationTab? activeTab}) {
    return NavigationState(activeTab: activeTab ?? this.activeTab);
  }

  @override
  List<Object?> get props => [activeTab];
}
