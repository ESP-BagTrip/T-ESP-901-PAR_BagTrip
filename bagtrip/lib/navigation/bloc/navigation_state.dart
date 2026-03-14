part of 'navigation_bloc.dart';

enum NavigationTab { planifier, trips, profile }

class NavigationState extends Equatable {
  final NavigationTab activeTab;

  const NavigationState({this.activeTab = NavigationTab.trips});

  NavigationState copyWith({NavigationTab? activeTab}) {
    return NavigationState(activeTab: activeTab ?? this.activeTab);
  }

  @override
  List<Object?> get props => [activeTab];
}
