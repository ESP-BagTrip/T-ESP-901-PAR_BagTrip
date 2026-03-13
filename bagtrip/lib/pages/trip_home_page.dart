import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/trips/view/trip_home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripHomePage extends StatelessWidget {
  final String tripId;

  const TripHomePage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value:
          context.read<TripManagementBloc>()..add(LoadTripHome(tripId: tripId)),
      child: TripHomeView(tripId: tripId),
    );
  }
}
