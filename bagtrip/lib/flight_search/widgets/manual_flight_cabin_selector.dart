import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cabin class selector: label "CABIN CLASS" + 3 pills (Economy, Premium, Business).
class ManualFlightCabinSelector extends StatelessWidget {
  const ManualFlightCabinSelector({super.key, required this.state});

  final FlightSearchLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.travelClassEconomy,
      l10n.travelClassPremiumEconomy,
      l10n.travelClassBusiness,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.cabinClassLabel.toUpperCase(),
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ColorName.hint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(labels.length, (index) {
            final selected = state.selectedClass == index;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < labels.length - 1 ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap:
                      () => context.read<FlightSearchBloc>().add(
                        SetTravelClass(index),
                      ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? ColorName.primary : ColorName.surface,
                      borderRadius: AppRadius.pill,
                      boxShadow:
                          selected
                              ? [
                                BoxShadow(
                                  color: ColorName.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            selected
                                ? ColorName.surface
                                : ColorName.primaryTrueDark,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
