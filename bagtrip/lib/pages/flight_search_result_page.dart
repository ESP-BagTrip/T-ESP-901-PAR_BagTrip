import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bagtrip/flightSearchResult/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/flightSearchResult/widgets/flight_search_result_widget.dart';

class FlightSearchResultPage extends StatelessWidget {
  const FlightSearchResultPage({super.key});

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
                    departureCode: 'CDG',
                    arrivalCode: 'FCO',
                    departureDate: DateTime.now(),
                    adults: 1,
                    children: 0,
                    infants: 0,
                    travelClass: 'Economy',
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
