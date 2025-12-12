import 'package:bagtrip/flightSearchResult/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/flightSearchResult/models/flight_search_arguments.dart';
import 'package:bagtrip/flightSearchResult/widgets/flight_search_result_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FlightSearchResultPage extends StatelessWidget {
  final FlightSearchArguments arguments;

  const FlightSearchResultPage({super.key, required this.arguments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats de recherche'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F3A5F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: BlocProvider(
        create:
            (context) =>
                FlightSearchResultBloc()..add(
                  LoadFlights(
                    departureCode: arguments.departureCode,
                    arrivalCode: arguments.arrivalCode,
                    departureDate: arguments.departureDate,
                    returnDate: arguments.returnDate,
                    adults: arguments.adults,
                    children: arguments.children,
                    infants: arguments.infants,
                    travelClass: arguments.travelClass,
                  ),
                ),
        child: const SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: FlightSearchResultView(),
            ),
          ),
        ),
      ),
    );
  }
}
