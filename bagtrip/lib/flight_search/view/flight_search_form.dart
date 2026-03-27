import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/flight_search_result/models/flight_search_arguments.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/flight_search/widgets/manual_flight_airports_card.dart';
import 'package:bagtrip/flight_search/widgets/manual_flight_cabin_selector.dart';
import 'package:bagtrip/flight_search/widgets/manual_flight_date_cards.dart';
import 'package:bagtrip/flight_search/widgets/manual_flight_header.dart';
import 'package:bagtrip/flight_search/widgets/manual_flight_trip_details_card.dart';
import 'package:bagtrip/flight_search/widgets/multi_destination_form.dart';
import 'package:bagtrip/flight_search/widgets/trip_type_selector.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/navigation/route_definitions.dart';

class FlightSearchForm extends StatelessWidget {
  const FlightSearchForm({super.key});

  static const double _sectionSpacing = 24;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlightSearchBloc, FlightSearchState>(
      listener: (context, state) {
        if (state is FlightSearchLoaded && state.error != null) {
          if (state.searchResults == null || state.searchResults!.isEmpty) {
            AppSnackBar.showError(
              context,
              message: toUserFriendlyMessage(
                state.error!,
                AppLocalizations.of(context)!,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final loadedState = state is FlightSearchLoaded
            ? state
            : FlightSearchLoaded();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            const ManualFlightHeader(),
            const SizedBox(height: _sectionSpacing),
            TripTypeSelector(state: loadedState),
            const SizedBox(height: _sectionSpacing),
            if (loadedState.tripTypeIndex == 2)
              MultiDestinationForm(state: loadedState)
            else ...[
              ManualFlightAirportsCard(state: loadedState),
              const SizedBox(height: _sectionSpacing),
              ManualFlightDateCards(state: loadedState),
            ],
            const SizedBox(height: _sectionSpacing),
            ManualFlightCabinSelector(state: loadedState),
            const SizedBox(height: _sectionSpacing),
            ManualFlightTripDetailsCard(state: loadedState),
            const SizedBox(height: 32),
            _SearchFlightsButton(
              onPressed: () => _onSearch(context, loadedState),
            ),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  void _onSearch(BuildContext context, FlightSearchLoaded loadedState) {
    final classMap = {0: 'ECONOMY', 1: 'PREMIUM_ECONOMY', 2: 'BUSINESS'};

    FlightSearchArguments? args;

    if (loadedState.tripTypeIndex == 2) {
      if (loadedState.multiDestSegments.isEmpty) {
        AppSnackBar.showError(
          context,
          message: AppLocalizations.of(context)!.errorAddAtLeastOneFlight,
        );
        return;
      }

      bool hasError = false;
      for (int i = 0; i < loadedState.multiDestSegments.length; i++) {
        final segment = loadedState.multiDestSegments[i];
        if (segment.departureAirport == null ||
            segment.arrivalAirport == null ||
            segment.departureDate == null) {
          hasError = true;
        }
      }

      if (hasError) {
        context.read<FlightSearchBloc>().add(ShowValidationErrors());
        AppSnackBar.showError(
          context,
          message: AppLocalizations.of(context)!.errorFillAllFields,
        );
        return;
      }

      final firstSegment = loadedState.multiDestSegments.first;
      args = FlightSearchArguments(
        departureCode: firstSegment.departureAirport!['iataCode'] ?? '',
        arrivalCode: firstSegment.arrivalAirport!['iataCode'] ?? '',
        departureDate: firstSegment.departureDate!,
        adults: loadedState.adults,
        children: loadedState.children,
        infants: loadedState.infants,
        travelClass: classMap[loadedState.selectedClass] ?? 'ECONOMY',
        multiDestSegments: loadedState.multiDestSegments,
        maxPrice: loadedState.maxPrice,
      );
    } else {
      bool hasError = false;
      if (loadedState.departureAirport == null) hasError = true;
      if (loadedState.arrivalAirport == null) hasError = true;
      if (loadedState.departureDate == null) hasError = true;
      if (loadedState.tripTypeIndex == 1 && loadedState.returnDate == null) {
        hasError = true;
      }

      if (hasError) {
        context.read<FlightSearchBloc>().add(ShowValidationErrors());
        AppSnackBar.showError(
          context,
          message: AppLocalizations.of(context)!.errorFillAllFields,
        );
        return;
      }

      args = FlightSearchArguments(
        departureCode: loadedState.departureAirport!['iataCode'] ?? '',
        arrivalCode: loadedState.arrivalAirport!['iataCode'] ?? '',
        departureDate: loadedState.departureDate!,
        returnDate: loadedState.returnDate,
        adults: loadedState.adults,
        children: loadedState.children,
        infants: loadedState.infants,
        travelClass: classMap[loadedState.selectedClass] ?? 'ECONOMY',
        maxPrice: loadedState.maxPrice,
      );
    }

    if (context.mounted) {
      FlightSearchResultRoute($extra: args).push(context);
    }
  }
}

class _SearchFlightsButton extends StatelessWidget {
  const _SearchFlightsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ColorName.primary, ColorName.secondary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.3),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: ColorName.surface,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.searchFlightButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: FontFamily.b612,
                    fontWeight: FontWeight.w600,
                    color: ColorName.surface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
