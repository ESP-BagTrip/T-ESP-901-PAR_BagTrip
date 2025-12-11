import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/flightSearchResult/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flightSearchResult/widgets/date_selector.dart';
import 'package:bagtrip/flightSearchResult/widgets/filter_button.dart';
import 'package:bagtrip/flightSearchResult/widgets/flight_card.dart';
import 'package:bagtrip/flightSearchResult/widgets/flight_search_result_shimmer.dart';

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
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is FlightSearchResultLoaded) {
          return SingleChildScrollView(
            child: Column(
              children: [
                DateSelector(selectedDateIndex: state.selectedDateIndex),
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
                        context.read<FlightSearchResultBloc>().add(
                          SelectFlight(flight),
                        );
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
