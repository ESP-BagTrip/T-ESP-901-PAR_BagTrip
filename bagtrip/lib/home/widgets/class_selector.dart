import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_flight_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClassSelector extends StatelessWidget {
  final HomeFlightLoaded state;

  const ClassSelector({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final labels = ['Économique', 'Premium', 'Business'];
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
                    selected ? ColorName.secondary : ColorName.primarySoftLight,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.large16,
                ),
                elevation: 0,
              ),
              onPressed: () {
                context.read<HomeFlightBloc>().add(SetTravelClass(i));
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
    );
  }
}
