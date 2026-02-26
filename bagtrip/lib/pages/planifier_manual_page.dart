import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/home/bloc/home_flight_bloc.dart';
import 'package:bagtrip/home/view/home_flight_form.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlanifierManualPage extends StatelessWidget {
  const PlanifierManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => HomeFlightBloc(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(l10n.planifierManualTitle),
          elevation: 0,
          backgroundColor: ColorName.backgroundGradientStart,
          foregroundColor: AppColors.onSurface,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorName.backgroundGradientStart,
                ColorName.backgroundGradientMid,
                ColorName.backgroundGradientEnd,
              ],
            ),
          ),
          child: const SafeArea(
            left: false,
            right: false,
            child: HomeFlightForm(),
          ),
        ),
      ),
    );
  }
}
