import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClassSelector extends StatelessWidget {
  final FlightSearchLoaded state;

  const ClassSelector({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.travelClassEconomy,
      l10n.travelClassPremiumEconomy,
      l10n.travelClassBusiness,
    ];
    return Row(
      children: List.generate(labels.length, (i) {
        final selected = state.selectedClass == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSize.height42),
                padding: AppSpacing.allEdgeInsetSpace8,
                backgroundColor:
                    selected ? ColorName.secondary : ColorName.primaryLight,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.large16,
                ),
                elevation: 0,
              ),
              onPressed: () {
                context.read<FlightSearchBloc>().add(SetTravelClass(i));
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    color: selected ? AppColors.surface : ColorName.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
