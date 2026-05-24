import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flight_search_result/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/flight_search_result/widgets/filter_dialog.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FilterButton extends StatelessWidget {
  const FilterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlightSearchResultBloc, FlightSearchResultState>(
      builder: (context, state) {
        if (state is! FlightSearchResultLoaded) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => FilterDialog(state: state),
            );
          },
          child: Container(
            // padding: AppSpacing.allEdgeInsetSpace16,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.large16,
              border: Border.all(color: ColorName.primarySoftLight),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: ColorName.secondary,
                    borderRadius: AppRadius.large16,
                  ),
                  child: const Icon(Icons.tune, color: AppColors.surface),
                ),
                const SizedBox(width: AppSpacing.space16),
                const Expanded(
                  child: Text(
                    'Ajouter vos filtres',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorName.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
