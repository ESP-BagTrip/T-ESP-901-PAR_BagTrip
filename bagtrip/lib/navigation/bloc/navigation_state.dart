part of 'navigation_bloc.dart';

enum NavigationTab { map, budget, planifier, profile }

class NavigationState extends Equatable {
  final NavigationTab activeTab;

  const NavigationState({this.activeTab = NavigationTab.planifier});

  NavigationState copyWith({NavigationTab? activeTab}) {
    return NavigationState(activeTab: activeTab ?? this.activeTab);
  }

  @override
  List<Object?> get props => [activeTab];
}
