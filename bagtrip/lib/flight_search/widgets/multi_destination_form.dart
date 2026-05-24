import 'package:bagtrip/components/custom_calendar_picker.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/flight_search/models/airport_type.dart';
import 'package:bagtrip/flight_search/widgets/airport_field.dart';
import 'package:bagtrip/flight_search/widgets/date_block.dart';
import 'package:bagtrip/flight_search/widgets/section_card.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../design/tokens.dart';

class MultiDestinationForm extends StatelessWidget {
  final FlightSearchLoaded state;

  const MultiDestinationForm({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        ...List.generate(state.multiDestSegments.length, (index) {
          final segment = state.multiDestSegments[index];
          return SectionCard(
            margin: AppSpacing.onlyBottomSpace16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.multiDestFlightTitle(index + 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ColorName.secondary,
                        fontFamily: FontFamily.b612,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (state.multiDestSegments.length > 2)
                      GestureDetector(
                        onTap: () {
                          context.read<FlightSearchBloc>().add(
                            RemoveFlightSegment(index),
                          );
                        },
                        child: const Icon(
                          Icons.close,
                          color: ColorName.error,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                AirportField(
                  icon: Icons.flight_takeoff,
                  label: l10n.multiDestDepartureHint.toUpperCase(),
                  type: AirportType.departure,
                  value: segment.departureAirport,
                  onSelected: (airport, _) {
                    if (airport != null) {
                      context.read<FlightSearchBloc>().add(
                        SelectMultiDestDepartureAirport(index, airport),
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
                AirportField(
                  icon: Icons.flight_land,
                  label: l10n.multiDestArrivalHint.toUpperCase(),
                  type: AirportType.arrival,
                  value: segment.arrivalAirport,
                  onSelected: (airport, _) {
                    if (airport != null) {
                      context.read<FlightSearchBloc>().add(
                        SelectMultiDestArrivalAirport(index, airport),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                DateBlock(
                  label: l10n.multiDestDateHint,
                  date: segment.departureDate,
                  onTap: () async {
                    DateTime minDate = DateTime.now();
                    if (index > 0) {
                      final previousDate =
                          state.multiDestSegments[index - 1].departureDate;
                      if (previousDate != null) {
                        minDate = previousDate;
                      }
                    }

                    final initialDate = segment.departureDate ?? minDate;

                    final pickedDate = await showCustomCalendarPicker(
                      context: context,
                      initialDate: initialDate.isBefore(minDate)
                          ? minDate
                          : initialDate,
                      firstDate: minDate,
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && context.mounted) {
                      context.read<FlightSearchBloc>().add(
                        SetMultiDestDate(index, pickedDate.startDate),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            context.read<FlightSearchBloc>().add(AddFlightSegment());
          },
          icon: const Icon(Icons.add, color: ColorName.secondary),
          label: Text(
            l10n.multiDestAddFlightButton,
            style: const TextStyle(
              color: ColorName.secondary,
              fontFamily: FontFamily.b612,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
