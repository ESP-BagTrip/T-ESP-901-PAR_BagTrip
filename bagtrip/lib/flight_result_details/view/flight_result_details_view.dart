import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flight_result_details/bloc/flight_result_details_bloc.dart';
import 'package:bagtrip/flight_result_details/widgets/baggage_info_card.dart';
import 'package:bagtrip/flight_result_details/widgets/class_info_card.dart';
import 'package:bagtrip/flight_result_details/widgets/fare_info_card.dart';
import 'package:bagtrip/flight_result_details/widgets/flight_detail_card.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class FlightResultDetailsView extends StatelessWidget {
  const FlightResultDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PersonalizationColors.gradientStart,
      appBar: AppBar(
        backgroundColor: PersonalizationColors.gradientStart,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ColorName.secondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.selectYourRate,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: ColorName.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PersonalizationColors.backgroundGradient,
          ),
        ),
        child: BlocBuilder<FlightResultDetailsBloc, FlightResultDetailsState>(
          builder: (context, state) {
            if (state is! FlightResultDetailsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final flight = state.flight;

            // Helper to format date
            String formatDate(DateTime? date) {
              if (date == null) return '';
              // Example: "Lundi 2 septembre"
              final locale = Localizations.localeOf(context).toString();
              return DateFormat('EEEE d MMMM', locale).format(date);
            }

            String getStopsLabel(int stops) {
              return AppLocalizations.of(context)!.stopsLabel(stops);
            }

            Color getStopsColor(int stops) {
              return stops == 0 ? ColorName.secondary : ColorName.warning;
            }

            String formatTicketingDate(String dateStr) {
              if (dateStr.isEmpty) return '';
              try {
                final date = DateTime.parse(dateStr);
                return DateFormat('dd/MM/yyyy').format(date);
              } catch (_) {
                return dateStr;
              }
            }

            return SingleChildScrollView(
              padding: AppSpacing.allEdgeInsetSpace16,
              child: Column(
                children: [
                  FlightDetailCard(
                    title: AppLocalizations.of(context)!.outboundFlight,
                    icon: Icons.flight_takeoff,
                    date: formatDate(flight.departureDateTime),
                    departureTime: flight.departureTime,
                    departureAirport: flight.departureCode,
                    arrivalTime: flight.arrivalTime,
                    arrivalAirport: flight.arrivalCode,
                    duration: flight.duration,
                    airline: flight.airline, // Should be mapped to name ideally
                    aircraft: flight.aircraftType,
                    tagLabel: getStopsLabel(flight.outboundStops),
                    tagColor: getStopsColor(flight.outboundStops),
                  ),
                  const SizedBox(height: 16),
                  // Return Flight (if exists)
                  if (flight.returnDepartureTime != null) ...[
                    FlightDetailCard(
                      title: AppLocalizations.of(context)!.returnFlight,
                      icon: Icons.flight_land,
                      date: formatDate(flight.returnDepartureDateTime),
                      departureTime: flight.returnDepartureTime!,
                      departureAirport: flight.returnDepartureCode!,
                      arrivalTime: flight.returnArrivalTime!,
                      arrivalAirport: flight.returnArrivalCode!,
                      duration: flight.returnDuration ?? '',
                      airline: flight.returnAirline ?? flight.airline,
                      aircraft: flight.returnAircraftType ?? '',
                      tagLabel: getStopsLabel(flight.returnStops ?? 0),
                      tagColor: getStopsColor(flight.returnStops ?? 0),
                    ),
                    const SizedBox(height: 16),
                  ],
                  BaggageInfoCard(
                    checkedBags: flight.checkedBags,
                    cabinBags: flight.cabinBags,
                  ),
                  const SizedBox(height: 16),
                  ClassInfoCard(
                    bookingClass: flight.bookingClass,
                    cabinClass: flight.cabinClass,
                    fareBasis: flight.fareBasis,
                  ),
                  const SizedBox(height: 16),
                  FareInfoCard(
                    price: flight.price,
                    basePrice: flight.basePrice,
                    numberOfBookableSeats: flight.numberOfBookableSeats,
                    lastTicketingDate: formatTicketingDate(
                      flight.lastTicketingDate,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
