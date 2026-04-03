import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/flight_search_result/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/flight_search_result/models/flight_search_arguments.dart';
import 'package:bagtrip/flight_search_result/widgets/flight_search_result_widget.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/navigation/route_definitions.dart';

class FlightSearchResultPage extends StatelessWidget {
  final FlightSearchArguments arguments;

  const FlightSearchResultPage({super.key, required this.arguments});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: PersonalizationColors.gradientStartOf(brightness),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchResults),
        elevation: 0,
        backgroundColor: PersonalizationColors.gradientStartOf(brightness),
        foregroundColor: PersonalizationColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => const HomeRoute().go(context),
        ),
      ),
      body: BlocProvider(
        create: (context) => FlightSearchResultBloc()
          ..add(
            LoadFlights(
              tripId: arguments.tripId,
              departureCode: arguments.departureCode,
              arrivalCode: arguments.arrivalCode,
              departureDate: arguments.departureDate,
              returnDate: arguments.returnDate,
              adults: arguments.adults,
              children: arguments.children,
              infants: arguments.infants,
              travelClass: arguments.travelClass,
              multiDestSegments: arguments.multiDestSegments,
              maxPrice: arguments.maxPrice,
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
