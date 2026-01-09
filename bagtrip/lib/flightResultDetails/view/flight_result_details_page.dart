import 'package:bagtrip/flightResultDetails/bloc/flight_result_details_bloc.dart';
import 'package:bagtrip/flightResultDetails/view/flight_result_details_view.dart';
import 'package:bagtrip/flightSearchResult/models/flight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FlightResultDetailsPage extends StatelessWidget {
  final Flight flight;
  final String? tripId;

  const FlightResultDetailsPage({super.key, required this.flight, this.tripId});

  static const String routePath = '/flight-result-details';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              FlightResultDetailsBloc()..add(LoadFlightDetails(flight)),
      child: FlightResultDetailsView(tripId: tripId),
    );
  }
}
