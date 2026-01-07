import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/home/bloc/home_flight_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PassengersRow extends StatelessWidget {
  final HomeFlightLoaded state;

  const PassengersRow({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Widget counter(
      String label,
      int value,
      VoidCallback add,
      VoidCallback sub,
    ) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: ColorName.secondary,
                  onPressed: sub,
                  padding: EdgeInsets.zero,
                  iconSize: 24,
                ),
              ),
              Container(
                padding: AppSpacing.allEdgeInsetSpace16,
                decoration: const BoxDecoration(
                  color: ColorName.primaryLight,
                  borderRadius: AppRadius.large16,
                ),
                child: Text('$value'),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: ColorName.secondary,
                  onPressed: add,
                  padding: EdgeInsets.zero,
                  iconSize: 24,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: AppSpacing.onlyRightSpace8,
            child: counter(
              AppLocalizations.of(context)!.passengersAdults,
              state.adults,
              () => context.read<HomeFlightBloc>().add(
                SetAdults(state.adults + 1),
              ),
              () => context.read<HomeFlightBloc>().add(
                SetAdults(state.adults > 1 ? state.adults - 1 : 1),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: AppSpacing.onlyRightSpace8,
            child: counter(
              AppLocalizations.of(context)!.passengersChildren,
              state.children,
              () => context.read<HomeFlightBloc>().add(
                SetChildren(state.children + 1),
              ),
              () => context.read<HomeFlightBloc>().add(
                SetChildren(state.children > 0 ? state.children - 1 : 0),
              ),
            ),
          ),
        ),
        Expanded(
          child: counter(
            AppLocalizations.of(context)!.passengersInfants,
            state.infants,
            () => context.read<HomeFlightBloc>().add(
              SetInfants(state.infants + 1),
            ),
            () => context.read<HomeFlightBloc>().add(
              SetInfants(state.infants > 0 ? state.infants - 1 : 0),
            ),
          ),
        ),
      ],
    );
  }
}
