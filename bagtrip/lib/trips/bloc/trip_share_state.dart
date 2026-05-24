part of 'trip_share_bloc.dart';

abstract class TripShareState {}

class TripShareInitial extends TripShareState {}

class TripShareLoading extends TripShareState {}

class TripShareLoaded extends TripShareState {
  final List<TripShare> shares;
  final List<PendingInvite> pendingInvites;
  TripShareLoaded({required this.shares, this.pendingInvites = const []});
}

class TripShareInvitePending extends TripShareState {
  final String inviteToken;
  TripShareInvitePending({required this.inviteToken});
}

class TripShareError extends TripShareState {
  final AppError error;
  TripShareError({required this.error});
}

class TripShareQuotaExceeded extends TripShareState {}
