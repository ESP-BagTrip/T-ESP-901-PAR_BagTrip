import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_flight_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PassengersRow extends StatelessWidget {
  final HomeFlightLoaded state;

  const PassengersRow({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Widget buildPassengerRow({
      required String label,
      required String description,
      required int value,
      required VoidCallback onAdd,
      required VoidCallback onRemove,
      bool isLast = false,
    }) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ColorName.primary,
                          fontFamily: FontFamily.b612,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorName.primary.withValues(alpha: 0.6),
                          fontFamily: FontFamily.b612,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ColorName.primary.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.remove),
                        color: ColorName.primary,
                        onPressed: onRemove,
                        iconSize: 20,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$value',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorName.primary,
                          fontFamily: FontFamily.b612,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: ColorName.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        color: Colors.white,
                        onPressed: onAdd,
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
            ),
          ),
          if (!isLast)
            Divider(height: 1, color: ColorName.primary.withValues(alpha: 0.1)),
        ],
      );
    }

    return Column(
      children: [
        buildPassengerRow(
          label: AppLocalizations.of(context)!.passengersAdults,
          description: AppLocalizations.of(context)!.passengersAdultsDesc,
          value: state.adults,
          onAdd:
              () => context.read<HomeFlightBloc>().add(
                SetAdults(state.adults + 1),
              ),
          onRemove:
              () => context.read<HomeFlightBloc>().add(
                SetAdults(state.adults > 1 ? state.adults - 1 : 1),
              ),
        ),
        buildPassengerRow(
          label: AppLocalizations.of(context)!.passengersChildren,
          description: AppLocalizations.of(context)!.passengersChildrenDesc,
          value: state.children,
          onAdd:
              () => context.read<HomeFlightBloc>().add(
                SetChildren(state.children + 1),
              ),
          onRemove:
              () => context.read<HomeFlightBloc>().add(
                SetChildren(state.children > 0 ? state.children - 1 : 0),
              ),
        ),
        buildPassengerRow(
          label: AppLocalizations.of(context)!.passengersInfants,
          description: AppLocalizations.of(context)!.passengersInfantsDesc,
          value: state.infants,
          onAdd:
              () => context.read<HomeFlightBloc>().add(
                SetInfants(state.infants + 1),
              ),
          onRemove:
              () => context.read<HomeFlightBloc>().add(
                SetInfants(state.infants > 0 ? state.infants - 1 : 0),
              ),
          isLast: true,
        ),
      ],
    );
  }
}
