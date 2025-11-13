part of 'navigation_bloc.dart';

sealed class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class NavigationTabChanged extends NavigationEvent {
  final NavigationTab tab;

  const NavigationTabChanged(this.tab);

  @override
  List<Object?> get props => [tab];
}
