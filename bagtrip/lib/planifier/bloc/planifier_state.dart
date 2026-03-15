part of 'planifier_bloc.dart';

@immutable
sealed class PlanifierState {}

final class PlanifierInitial extends PlanifierState {}

final class PlanifierLoaded extends PlanifierState {
  final int inProgressCount;
  final Trip? nextTrip;
  final int? daysUntilNextTrip;

  PlanifierLoaded({
    this.inProgressCount = 0,
    this.nextTrip,
    this.daysUntilNextTrip,
  });
}
