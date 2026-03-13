import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/trips/view/trips_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripsListPage extends StatelessWidget {
  const TripsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<TripManagementBloc>()..add(LoadTrips()),
      child: const TripsListView(),
    );
  }
}
