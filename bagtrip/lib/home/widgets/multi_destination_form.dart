import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_flight_bloc.dart';
import 'package:bagtrip/home/models/airport_type.dart';
import 'package:bagtrip/home/widgets/airport_search_field.dart';
import 'package:bagtrip/home/widgets/home_date_field.dart';
import 'package:bagtrip/home/widgets/home_field_row.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MultiDestinationForm extends StatelessWidget {
  final HomeFlightLoaded state;

  const MultiDestinationForm({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        ...List.generate(state.multiDestSegments.length, (index) {
          final segment = state.multiDestSegments[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.multiDestFlightTitle(index + 1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: FontFamily.b612,
                      fontWeight: FontWeight.w700,
                      color: ColorName.primary,
                    ),
                  ),
                  if (state.multiDestSegments.length > 2)
                    IconButton(
                      icon: const Icon(Icons.close, color: ColorName.error),
                      onPressed: () {
                        context.read<HomeFlightBloc>().add(
                          RemoveFlightSegment(index),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSize.boxSize8),
              HomeFieldRow(
                icon: Icons.flight_takeoff,
                field: AirportSearchField(
                  type: AirportType.departure,
                  hintText: l10n.multiDestDepartureHint,
                  initialValue: segment.departureAirport,
                  hasError:
                      state.showValidationErrors &&
                      segment.departureAirport == null,
                  onSelected: (airport, _) {
                    if (airport != null) {
                      context.read<HomeFlightBloc>().add(
                        SelectMultiDestDepartureAirport(index, airport),
                      );
                    }
                  },
                ),
              ),
              HomeFieldRow(
                icon: Icons.flight_land,
                field: AirportSearchField(
                  type: AirportType.arrival,
                  hintText: l10n.multiDestArrivalHint,
                  initialValue: segment.arrivalAirport,
                  hasError:
                      state.showValidationErrors &&
                      segment.arrivalAirport == null,
                  onSelected: (airport, _) {
                    if (airport != null) {
                      context.read<HomeFlightBloc>().add(
                        SelectMultiDestArrivalAirport(index, airport),
                      );
                    }
                  },
                ),
              ),
              HomeFieldRow(
                icon: Icons.calendar_today,
                field: HomeDateField(
                  hint: l10n.multiDestDateHint,
                  value: segment.departureDate,
                  hasError:
                      state.showValidationErrors &&
                      segment.departureDate == null,
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

                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate:
                          initialDate.isBefore(minDate) ? minDate : initialDate,
                      firstDate: minDate,
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && context.mounted) {
                      context.read<HomeFlightBloc>().add(
                        SetMultiDestDate(index, pickedDate),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSize.boxSize16),
            ],
          );
        }),
        TextButton.icon(
          onPressed: () {
            context.read<HomeFlightBloc>().add(AddFlightSegment());
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
