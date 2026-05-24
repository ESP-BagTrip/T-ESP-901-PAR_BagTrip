import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

@immutable
sealed class TripLocationsState {
  const TripLocationsState();
}

final class TripLocationsLoading extends TripLocationsState {
  const TripLocationsLoading();
}

final class TripLocationsLoaded extends TripLocationsState {
  final Trip? trip;
  final List<Activity> activities;
  final List<Accommodation> accommodations;

  const TripLocationsLoaded({
    required this.trip,
    required this.activities,
    required this.accommodations,
  });
}

class TripLocationsCubit extends Cubit<TripLocationsState> {
  final TripRepository _tripRepository;
  final ActivityRepository _activityRepository;
  final AccommodationRepository _accommodationRepository;

  TripLocationsCubit({
    TripRepository? tripRepository,
    ActivityRepository? activityRepository,
    AccommodationRepository? accommodationRepository,
  }) : _tripRepository = tripRepository ?? getIt<TripRepository>(),
       _activityRepository = activityRepository ?? getIt<ActivityRepository>(),
       _accommodationRepository =
           accommodationRepository ?? getIt<AccommodationRepository>(),
       super(const TripLocationsLoading());

  Future<void> load(String tripId) async {
    final results = await Future.wait([
      _tripRepository.getTripById(tripId),
      _activityRepository.getActivities(tripId),
      _accommodationRepository.getByTrip(tripId),
    ]);
    if (isClosed) return;

    final tripResult = results[0] as Result<Trip>;
    final activitiesResult = results[1] as Result<List<Activity>>;
    final accommodationsResult = results[2] as Result<List<Accommodation>>;

    emit(
      TripLocationsLoaded(
        trip: tripResult.dataOrNull,
        activities: activitiesResult.dataOrNull ?? const [],
        accommodations: accommodationsResult.dataOrNull ?? const [],
      ),
    );
  }
}
