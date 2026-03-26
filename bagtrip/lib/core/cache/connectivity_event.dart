part of 'connectivity_bloc.dart';

@immutable
sealed class ConnectivityEvent {}

final class ConnectivityChanged extends ConnectivityEvent {
  final bool isOnline;
  ConnectivityChanged({required this.isOnline});
}
