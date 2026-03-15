import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/flight_search/view/flight_search_form.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/navigation/route_definitions.dart';

/// Second step of manual trip planning: flight search form.
/// Shown after the destination step when user taps "Suivant".
class PlanifierManualFlightPage extends StatelessWidget {
  const PlanifierManualFlightPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => FlightSearchBloc(),
      child: Scaffold(
        backgroundColor: PersonalizationColors.gradientStart,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => const HomeRoute().go(context),
          ),
          title: Text(
            l10n.findYourFlightTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: PersonalizationColors.textPrimary,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: PersonalizationColors.gradientStart,
          foregroundColor: PersonalizationColors.textPrimary,
        ),
        body: const SafeArea(
          left: false,
          right: false,
          child: FlightSearchForm(),
        ),
      ),
    );
  }
}
