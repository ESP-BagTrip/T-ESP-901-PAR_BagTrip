import 'package:bagtrip/flightResultDetails/bloc/flight_result_details_bloc.dart';
import 'package:bagtrip/flightResultDetails/view/flight_result_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FlightResultDetailsPage extends StatelessWidget {
  const FlightResultDetailsPage({super.key});

  static const String routePath = '/flight-result-details';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlightResultDetailsBloc()..add(LoadFlightDetails()),
      child: const FlightResultDetailsView(),
    );
  }
}
