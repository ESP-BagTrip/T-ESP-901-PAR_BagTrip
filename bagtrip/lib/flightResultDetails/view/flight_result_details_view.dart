import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flightResultDetails/bloc/flight_result_details_bloc.dart';
import 'package:bagtrip/flightResultDetails/widgets/baggage_info_card.dart';
import 'package:bagtrip/flightResultDetails/widgets/class_info_card.dart';
import 'package:bagtrip/flightResultDetails/widgets/fare_info_card.dart';
import 'package:bagtrip/flightResultDetails/widgets/flight_detail_card.dart';
import 'package:bagtrip/flightSearchResult/models/flight.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ColorName.secondary),
          onPressed: () => Navigator.of(context).pop(),
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
      body: BlocConsumer<FlightResultDetailsBloc, FlightResultDetailsState>(
        listener: (context, state) {
          if (state is FlightPriceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.error(state.message),
                ),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is FlightPriceConfirmed) {
            if (!state.priceChanged) {
              // Same price, navigate to payment
              context.pushNamed('payment', extra: state.flight);
            } else {
              // Price changed, show snackbar (optional, as UI updates too)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attention : Le prix a changé !'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is FlightPriceConfirming) {
            return const Center(child: CircularProgressIndicator());
          }

          final Flight flight;
          bool priceChanged = false;
          Flight? oldFlight;

          if (state is FlightResultDetailsLoaded) {
            flight = state.flight;
          } else if (state is FlightPriceConfirmed) {
            flight = state.flight;
            priceChanged = state.priceChanged;
            oldFlight = state.oldFlight;
          } else if (state is FlightPriceError) {
            flight = state.originalFlight;
          } else {
            return const Center(child: CircularProgressIndicator());
          }

          // Helper to format date
          String formatDate(DateTime? date) {
            if (date == null) return '';
            final locale = Localizations.localeOf(context).toString();
            return DateFormat('EEEE d MMMM', locale).format(date);
          }

          String getStopsLabel(int stops) {
            return AppLocalizations.of(context)!.stopsLabel(stops);
          }

          Color getStopsColor(int stops) {
            return stops == 0 ? ColorName.secondary : Colors.orange;
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
                if (priceChanged && oldFlight != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Le prix de ce vol a changé.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                'Ancien prix : ${oldFlight.price.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Nouveau prix : ${flight.price.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ColorName.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                FlightDetailCard(
                  title: AppLocalizations.of(context)!.outboundFlight,
                  icon: Icons.flight_takeoff,
                  date: formatDate(flight.departureDateTime),
                  departureTime: flight.departureTime,
                  departureAirport: flight.departureCode,
                  arrivalTime: flight.arrivalTime,
                  arrivalAirport: flight.arrivalCode,
                  duration: flight.duration,
                  airline: flight.airline,
                  aircraft: flight.aircraftType,
                  tagLabel: getStopsLabel(flight.outboundStops),
                  tagColor: getStopsColor(flight.outboundStops),
                ),
                const SizedBox(height: 16),
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
                  onPressed: () {
                    context.read<FlightResultDetailsBloc>().add(
                      ConfirmFlightPrice(),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
