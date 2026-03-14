part of 'navigation_bloc.dart';

sealed class NavigationEvent {
  const NavigationEvent();
}

class NavigationTabChanged extends NavigationEvent {
  final NavigationTab tab;

  const NavigationTabChanged(this.tab);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationTabChanged &&
          runtimeType == other.runtimeType &&
          tab == other.tab;

  @override
  int get hashCode => tab.hashCode;
}
