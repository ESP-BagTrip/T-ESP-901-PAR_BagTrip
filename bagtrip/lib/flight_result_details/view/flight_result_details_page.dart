import 'package:bagtrip/flight_result_details/bloc/flight_result_details_bloc.dart';
import 'package:bagtrip/flight_result_details/view/flight_result_details_view.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FlightResultDetailsPage extends StatelessWidget {
  final Flight flight;

  const FlightResultDetailsPage({super.key, required this.flight});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FlightResultDetailsBloc()..add(LoadFlightDetails(flight)),
      child: const FlightResultDetailsView(),
    );
  }
}
