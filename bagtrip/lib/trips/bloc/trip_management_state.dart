part of 'trip_management_bloc.dart';

sealed class TripManagementState {}

class TripManagementInitial extends TripManagementState {}

class TripsLoading extends TripManagementState {}

class TripCreating extends TripManagementState {}

class TripDeleting extends TripManagementState {}

class TripTabData {
  final List<Trip> trips;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  bool get hasMore => currentPage < totalPages;

  const TripTabData({
    this.trips = const [],
    this.currentPage = 0,
    this.totalPages = 0,
    this.isLoadingMore = false,
  });

  TripTabData copyWith({
    List<Trip>? trips,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return TripTabData(
      trips: trips ?? this.trips,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TripsLoaded extends TripManagementState {
  final TripGrouped groupedTrips;

  TripsLoaded({required this.groupedTrips});
}

class TripsTabLoaded extends TripManagementState {
  final Map<String, TripTabData> tabs;

  TripsTabLoaded({required this.tabs});

  TripTabData getTab(String status) => tabs[status] ?? const TripTabData();
}

class TripError extends TripManagementState {
  final AppError error;

  TripError({required this.error});
}

class TripHomeLoading extends TripManagementState {}

class TripHomeLoaded extends TripManagementState {
  final TripHome tripHome;

  TripHomeLoaded({required this.tripHome});
}

class TripCreated extends TripManagementState {
  final Trip trip;

  TripCreated({required this.trip});
}

class TripDeleted extends TripManagementState {}
