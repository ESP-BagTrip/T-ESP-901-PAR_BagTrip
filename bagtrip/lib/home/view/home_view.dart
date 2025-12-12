import 'package:bagtrip/flightSearchResult/models/flight_search_arguments.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../design/tokens.dart';
import '../../gen/fonts.gen.dart';
import '../bloc/home_flight_bloc.dart';
import '../models/airport_type.dart';
import '../widgets/airport_search_field.dart';
import '../widgets/class_selector.dart';
import '../widgets/home_date_field.dart';
import '../widgets/home_field_row.dart';
import '../widgets/home_price_field.dart';
import '../widgets/home_top_cards.dart';
import '../widgets/passengers_row.dart';
import '../widgets/trip_type_selector.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeFlightBloc, HomeFlightState>(
      listener: (context, state) {
        if (state is HomeFlightLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: ColorName.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final loadedState =
            state is HomeFlightLoaded ? state : HomeFlightLoaded();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeTopCards(),
              const SizedBox(height: AppSize.boxSize16),
              TripTypeSelector(state: loadedState),
              const SizedBox(height: AppSize.boxSize8),
              HomeFieldRow(
                icon: Icons.flight_takeoff,
                field: AirportSearchField(
                  type: AirportType.departure,
                  hintText: AirportType.departure.hintText,
                  onSelected: (airport, selectedType) {
                    if (airport != null) {
                      context.read<HomeFlightBloc>().add(
                        SelectDepartureAirport(airport),
                      );
                    }
                  },
                ),
              ),
              HomeFieldRow(
                icon: Icons.flight_land,
                field: AirportSearchField(
                  type: AirportType.arrival,
                  hintText: AirportType.arrival.hintText,
                  onSelected: (airport, selectedType) {
                    if (airport != null) {
                      context.read<HomeFlightBloc>().add(
                        SelectArrivalAirport(airport),
                      );
                    }
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: HomeFieldRow(
                      icon: Icons.calendar_today,
                      field: HomeDateField(
                        hint: 'jj/mm/aaaa',
                        value: loadedState.departureDate,
                        onTap: () async {
                          final pickedDeparture = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDeparture != null && context.mounted) {
                            context.read<HomeFlightBloc>().add(
                              SetDepartureDate(pickedDeparture),
                            );

                            // Automatically open return date picker
                            final pickedReturn = await showDatePicker(
                              context: context,
                              initialDate: pickedDeparture,
                              firstDate: pickedDeparture,
                              lastDate: DateTime(2101),
                            );

                            if (pickedReturn != null && context.mounted) {
                              context.read<HomeFlightBloc>().add(
                                SetReturnDate(pickedReturn),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSize.boxSize8),
                  Expanded(
                    child: HomeFieldRow(
                      icon: Icons.calendar_today,
                      field: HomeDateField(
                        hint: 'jj/mm/aaaa',
                        value: loadedState.returnDate,
                        onTap: () async {
                          final initialDate =
                              loadedState.departureDate ?? DateTime.now();
                          final pickedReturn = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: initialDate,
                            lastDate: DateTime(2101),
                          );
                          if (pickedReturn != null && context.mounted) {
                            context.read<HomeFlightBloc>().add(
                              SetReturnDate(pickedReturn),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              HomeFieldRow(
                icon: Icons.euro_symbol,
                field: HomePriceField(
                  onPriceChanged: (price) {
                    context.read<HomeFlightBloc>().add(SetMaxPrice(price));
                  },
                ),
              ),
              const SizedBox(height: AppSize.boxSize16),
              const Text(
                'Classe de voyage',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: FontFamily.b612,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primary,
                ),
              ),
              const SizedBox(height: AppSize.boxSize8),
              ClassSelector(state: loadedState),
              const SizedBox(height: AppSize.boxSize16),
              const Text(
                'Passagers',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: FontFamily.b612,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primary,
                ),
              ),
              const SizedBox(height: AppSize.boxSize8),
              PassengersRow(state: loadedState),
              const SizedBox(height: AppSize.boxSize16),
              SizedBox(
                // height: AppSize.height42,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorName.secondary,
                    padding: AppSpacing.allEdgeInsetSpace16,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.large16,
                    ),
                  ),
                  onPressed: () {
                    if (loadedState.departureAirport == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez sélectionner un aéroport de départ',
                          ),
                          backgroundColor: ColorName.error,
                        ),
                      );
                      return;
                    }
                    if (loadedState.arrivalAirport == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez sélectionner un aéroport d\'arrivée',
                          ),
                          backgroundColor: ColorName.error,
                        ),
                      );
                      return;
                    }
                    if (loadedState.departureDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez sélectionner une date de départ',
                          ),
                          backgroundColor: ColorName.error,
                        ),
                      );
                      return;
                    }
                    // For round trip (index 1), return date is mandatory
                    if (loadedState.tripTypeIndex == 1 &&
                        loadedState.returnDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez sélectionner une date de retour',
                          ),
                          backgroundColor: ColorName.error,
                        ),
                      );
                      return;
                    }

                    // Map class index to string
                    final classMap = {
                      0: 'ECONOMY',
                      1: 'PREMIUM_ECONOMY',
                      2: 'BUSINESS',
                    };

                    final args = FlightSearchArguments(
                      departureCode:
                          loadedState.departureAirport!['iataCode'] ?? '',
                      arrivalCode:
                          loadedState.arrivalAirport!['iataCode'] ?? '',
                      departureDate: loadedState.departureDate!,
                      returnDate: loadedState.returnDate,
                      adults: loadedState.adults,
                      children: loadedState.children,
                      infants: loadedState.infants,
                      travelClass:
                          classMap[loadedState.selectedClass] ?? 'ECONOMY',
                    );

                    if (context.mounted) {
                      context.go('/flight-search-result', extra: args);
                    }
                  },
                  child:
                      loadedState.isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ColorName.primaryLight,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Rechercher votre vol',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: FontFamily.b612,
                              fontWeight: FontWeight.w700,
                              color: ColorName.primaryLight,
                            ),
                          ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
