part of 'home_bloc.dart';

sealed class HomeEvent {}

class LoadHome extends HomeEvent {}

class RefreshHome extends HomeEvent {}
