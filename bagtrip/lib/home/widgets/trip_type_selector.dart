import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_flight_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripTypeSelector extends StatelessWidget {
  final HomeFlightLoaded state;

  const TripTypeSelector({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final labels = ['Aller simple', 'Aller-retour', 'Multidestination'];
    return SizedBox(
      height: 42,
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == state.tripTypeIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSize.height42),
                  padding: AppSpacing.allEdgeInsetSpace8,
                  backgroundColor:
                      selected
                          ? ColorName.secondary
                          : ColorName.primarySoftLight,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.large16,
                  ),
                ),
                onPressed: () {
                  context.read<HomeFlightBloc>().add(SetTripType(i));
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      color: selected ? Colors.white : ColorName.primary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
