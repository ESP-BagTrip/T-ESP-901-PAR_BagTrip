import 'dart:ui';

import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Floating glass capsule for trip type: One-way | Round trip | Multi-city.
class TripTypeSelector extends StatelessWidget {
  const TripTypeSelector({super.key, required this.state});

  final FlightSearchLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.tripTypeOneWay,
      l10n.tripTypeRoundTrip,
      l10n.tripTypeMultiCity,
    ];

    return ClipRRect(
      borderRadius: AppRadius.large20,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ColorName.surface.withValues(alpha: 0.85),
            borderRadius: AppRadius.large20,
            border: Border.all(
              color: ColorName.primarySoftLight.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: List.generate(labels.length, (index) {
              final selected = index == state.tripTypeIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    context.read<FlightSearchBloc>().add(SetTripType(index));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? ColorName.primary : Colors.transparent,
                      borderRadius: AppRadius.large16,
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
              );
            }),
          ),
        ),
      ),
    );
  }
}
