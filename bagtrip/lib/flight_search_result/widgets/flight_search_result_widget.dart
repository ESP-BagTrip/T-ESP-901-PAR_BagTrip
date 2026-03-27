import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flight_search_result/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/flight_search_result/widgets/date_selector.dart';
import 'package:bagtrip/flight_search_result/widgets/filter_button.dart';
import 'package:bagtrip/flight_search_result/widgets/flight_card.dart';
import 'package:bagtrip/flight_search_result/widgets/flight_search_result_shimmer.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FlightSearchResultView extends StatelessWidget {
  const FlightSearchResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlightSearchResultBloc, FlightSearchResultState>(
      builder: (context, state) {
        if (state is FlightSearchResultLoading) {
          return const FlightSearchResultShimmer();
        }

        if (state is FlightSearchResultError) {
          return Center(
            child: Text(
              toUserFriendlyMessage(state.error, AppLocalizations.of(context)!),
            ),
          );
        }

        if (state is FlightSearchResultLoaded) {
          if (state.filteredFlights.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.airplanemode_inactive,
                      size: 64,
                      color: ColorName.primarySoftLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noFlightsFoundTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: FontFamily.b612,
                        fontWeight: FontWeight.w700,
                        color: ColorName.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.flights.isEmpty
                          ? AppLocalizations.of(context)!.noFlightsFoundMessage
                          : AppLocalizations.of(
                              context,
                            )!.noFlightsFoundPriceFilterMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: FontFamily.b612,
                        color: ColorName.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (state.flights.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.read<FlightSearchResultBloc>().add(
                            FilterFlightsByPrice(null),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorName.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.clearPriceFilterButton,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                DateSelector(
                  selectedDateIndex: state.selectedDateIndex,
                  departureDate: state.departureDate,
                  returnDate: state.returnDate,
                  flights: state.flights,
                ),
                const SizedBox(height: AppSpacing.space16),
                const FilterButton(),
                const SizedBox(height: AppSpacing.space16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.filteredFlights.length,
                  itemBuilder: (context, index) {
                    final flight = state.filteredFlights[index];
                    final isSelected = state.selectedFlight?.id == flight.id;

                    return FlightCard(
                      flight: flight,
                      isSelected: isSelected,
                      onTap: () {
                        if (context.mounted) {
                          context.read<FlightSearchResultBloc>().add(
                            SelectFlight(flight),
                          );
                          FlightResultDetailsRoute(
                            $extra: flight,
                          ).push(context);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
