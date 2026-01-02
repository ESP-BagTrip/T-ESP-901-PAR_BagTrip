import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flightSearchResult/models/flight_search_arguments.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_flight_bloc.dart';
import 'package:bagtrip/home/models/airport_type.dart';
import 'package:bagtrip/home/widgets/airport_search_field.dart';
import 'package:bagtrip/home/widgets/class_selector.dart';
import 'package:bagtrip/home/widgets/home_date_field.dart';
import 'package:bagtrip/home/widgets/home_field_row.dart';
import 'package:bagtrip/home/widgets/home_price_field.dart';
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

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TripTypeSelector(state: loadedState),
              const SizedBox(height: AppSize.boxSize8),
              if (loadedState.tripTypeIndex == 2)
                MultiDestinationForm(state: loadedState)
              else ...[
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Column(
                      children: [
                        HomeFieldRow(
                          icon: Icons.flight_takeoff,
                          field: AirportSearchField(
                            type: AirportType.departure,
                            hintText: AirportType.departure.getHintText(
                              context,
                            ),
                            initialValue: loadedState.departureAirport,
                            hasError:
                                loadedState.showValidationErrors &&
                                loadedState.departureAirport == null,
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
                            hintText: AirportType.arrival.getHintText(context),
                            initialValue: loadedState.arrivalAirport,
                            hasError:
                                loadedState.showValidationErrors &&
                                loadedState.arrivalAirport == null,
                            onSelected: (airport, selectedType) {
                              if (airport != null) {
                                context.read<HomeFlightBloc>().add(
                                  SelectArrivalAirport(airport),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 36,
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.swap_vert,
                            size: 20,
                            color: ColorName.secondary,
                          ),
                          onPressed: () {
                            context.read<HomeFlightBloc>().add(SwapAirports());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: HomeFieldRow(
                        icon: Icons.calendar_today,
                        field: HomeDateField(
                          hint: AppLocalizations.of(context)!.dateFormatHint,
                          value: loadedState.departureDate,
                          hasError:
                              loadedState.showValidationErrors &&
                              loadedState.departureDate == null,
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

                              if (loadedState.tripTypeIndex == 1) {
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
                            }
                          },
                        ),
                      ),
                    ),
                    if (loadedState.tripTypeIndex == 1) ...[
                      const SizedBox(width: AppSize.boxSize8),
                      Expanded(
                        child: HomeFieldRow(
                          icon: Icons.calendar_today,
                          field: HomeDateField(
                            hint: AppLocalizations.of(context)!.dateFormatHint,
                            value: loadedState.returnDate,
                            hasError:
                                loadedState.showValidationErrors &&
                                loadedState.returnDate == null,
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
                  ],
                ),
              ],
              HomeFieldRow(
                icon: Icons.euro_symbol,
                field: HomePriceField(
                  onPriceChanged: (price) {
                    context.read<HomeFlightBloc>().add(SetMaxPrice(price));
                  },
                ),
              ),
              const SizedBox(height: AppSize.boxSize16),
              Text(
                AppLocalizations.of(context)!.travelClassTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: FontFamily.b612,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primary,
                ),
              ),
              const SizedBox(height: AppSize.boxSize8),
              ClassSelector(state: loadedState),
              const SizedBox(height: AppSize.boxSize16),
              Text(
                AppLocalizations.of(context)!.passengersTitle,
                style: const TextStyle(
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
                height: AppSize.height42,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorName.secondary,
                    padding: AppSpacing.horizontalSpace16,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.large16,
                    ),
                  ),
                  onPressed: () {
                    final classMap = {
                      0: 'ECONOMY',
                      1: 'PREMIUM_ECONOMY',
                      2: 'BUSINESS',
                    };

                    FlightSearchArguments? args;

                    if (loadedState.tripTypeIndex == 2) {
                      if (loadedState.multiDestSegments.isEmpty) {
                        AppSnackBar.showError(
                          context,
                          message:
                              AppLocalizations.of(
                                context,
                              )!.errorAddAtLeastOneFlight,
                        );
                        return;
                      }

                      bool hasError = false;
                      for (
                        int i = 0;
                        i < loadedState.multiDestSegments.length;
                        i++
                      ) {
                        final segment = loadedState.multiDestSegments[i];
                        if (segment.departureAirport == null ||
                            segment.arrivalAirport == null ||
                            segment.departureDate == null) {
                          hasError = true;
                        }
                      }

                      if (hasError) {
                        context.read<HomeFlightBloc>().add(
                          ShowValidationErrors(),
                        );
                        AppSnackBar.showError(
                          context,
                          message:
                              AppLocalizations.of(context)!.errorFillAllFields,
                        );
                        return;
                      }

                      final firstSegment = loadedState.multiDestSegments.first;
                      args = FlightSearchArguments(
                        departureCode:
                            firstSegment.departureAirport!['iataCode'] ?? '',
                        arrivalCode:
                            firstSegment.arrivalAirport!['iataCode'] ?? '',
                        departureDate: firstSegment.departureDate!,
                        adults: loadedState.adults,
                        children: loadedState.children,
                        infants: loadedState.infants,
                        travelClass:
                            classMap[loadedState.selectedClass] ?? 'ECONOMY',
                        multiDestSegments: loadedState.multiDestSegments,
                        maxPrice: loadedState.maxPrice,
                      );
                    } else {
                      bool hasError = false;
                      if (loadedState.departureAirport == null) hasError = true;
                      if (loadedState.arrivalAirport == null) hasError = true;
                      if (loadedState.departureDate == null) hasError = true;
                      if (loadedState.tripTypeIndex == 1 &&
                          loadedState.returnDate == null) {
                        hasError = true;
                      }

                      if (hasError) {
                        context.read<HomeFlightBloc>().add(
                          ShowValidationErrors(),
                        );
                        AppSnackBar.showError(
                          context,
                          message:
                              AppLocalizations.of(context)!.errorFillAllFields,
                        );
                        return;
                      }

                      args = FlightSearchArguments(
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
                        maxPrice: loadedState.maxPrice,
                      );
                    }

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
                          : Text(
                            AppLocalizations.of(context)!.searchFlightButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: FontFamily.b612,
                              fontWeight: FontWeight.w700,
                              color: ColorName.primaryLight,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 100), // Bottom padding for scroll
            ],
          ),
        );
      },
    );
  }
}
