import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/flightSearchResult/models/flight_search_arguments.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_flight_bloc.dart';
import 'package:bagtrip/home/models/airport_type.dart';
import 'package:bagtrip/home/widgets/class_selector.dart';
import 'package:bagtrip/home/widgets/home_airport_field.dart';
import 'package:bagtrip/home/widgets/home_date_block.dart';
import 'package:bagtrip/home/widgets/home_price_field.dart';
import 'package:bagtrip/home/widgets/home_section_card.dart';
import 'package:bagtrip/home/widgets/multi_destination_form.dart';
import 'package:bagtrip/home/widgets/passengers_row.dart';
import 'package:bagtrip/home/widgets/trip_type_selector.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeFlightForm extends StatelessWidget {
  const HomeFlightForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeFlightBloc, HomeFlightState>(
      listener: (context, state) {
        if (state is HomeFlightLoaded && state.errorMessage != null) {
          AppSnackBar.showError(context, message: state.errorMessage!);
        }
      },
      builder: (context, state) {
        final loadedState =
            state is HomeFlightLoaded ? state : HomeFlightLoaded();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            TripTypeSelector(state: loadedState),
            const SizedBox(height: 24),
            if (loadedState.tripTypeIndex == 2)
              MultiDestinationForm(state: loadedState)
            else ...[
              // Departure / Destination Card
              HomeSectionCard(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        HomeAirportField(
                          icon: Icons.flight_takeoff,
                          label:
                              AppLocalizations.of(
                                context,
                              )!.departureLabel.toUpperCase(),
                          type: AirportType.departure,
                          value: loadedState.departureAirport,
                          onSelected: (airport, _) {
                            if (airport != null) {
                              context.read<HomeFlightBloc>().add(
                                SelectDepartureAirport(airport),
                              );
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(
                            height: 1,
                            color: ColorName.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        HomeAirportField(
                          icon: Icons.location_on_outlined,
                          label:
                              AppLocalizations.of(
                                context,
                              )!.destinationLabel.toUpperCase(),
                          type: AirportType.arrival,
                          value: loadedState.arrivalAirport,
                          onSelected: (airport, _) {
                            if (airport != null) {
                              context.read<HomeFlightBloc>().add(
                                SelectArrivalAirport(airport),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date Card
              HomeSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: ColorName.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.travelDatesLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ColorName.secondary,
                            fontFamily: FontFamily.b612,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: HomeDateBlock(
                            label: AppLocalizations.of(context)!.outboundLabel,
                            date: loadedState.departureDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2101),
                              );
                              if (picked != null && context.mounted) {
                                context.read<HomeFlightBloc>().add(
                                  SetDepartureDate(picked),
                                );
                              }
                            },
                          ),
                        ),
                        if (loadedState.tripTypeIndex == 1) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: HomeDateBlock(
                              label: AppLocalizations.of(context)!.returnLabel,
                              date: loadedState.returnDate,
                              onTap: () async {
                                final initial =
                                    loadedState.departureDate ?? DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate: initial,
                                  lastDate: DateTime(2101),
                                );
                                if (picked != null && context.mounted) {
                                  context.read<HomeFlightBloc>().add(
                                    SetReturnDate(picked),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Class Card
            HomeSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.airline_seat_recline_normal,
                        color: ColorName.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.travelClassTitle.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorName.secondary,
                          fontFamily: FontFamily.b612,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClassSelector(state: loadedState),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Passengers Card
            HomeSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: ColorName.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.passengersTitle.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorName.secondary,
                          fontFamily: FontFamily.b612,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PassengersRow(state: loadedState),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Options Bar (Budget, etc) - Simplified
            HomeSectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.euro_symbol, color: ColorName.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.maxBudgetLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ColorName.secondary,
                            fontFamily: FontFamily.b612,
                          ),
                        ),
                        HomePriceField(
                          onPriceChanged: (price) {
                            context.read<HomeFlightBloc>().add(
                              SetMaxPrice(price),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorName.primary, ColorName.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _onSearch(context, loadedState),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.searchFlightButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: FontFamily.b612,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  void _onSearch(BuildContext context, HomeFlightLoaded loadedState) {
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
        context.read<HomeFlightBloc>().add(ShowValidationErrors());
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
        context.read<HomeFlightBloc>().add(ShowValidationErrors());
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
      context.go('/flight-search-result', extra: args);
    }
  }
}
