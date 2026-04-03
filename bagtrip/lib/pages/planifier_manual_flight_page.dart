import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/flight_search/models/flight_search_prefill.dart';
import 'package:bagtrip/flight_search/view/flight_search_form.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Second step of manual trip planning: flight search form.
/// Shown after the destination step when user taps "Suivant".
class PlanifierManualFlightPage extends StatelessWidget {
  final FlightSearchPrefill? prefill;

  const PlanifierManualFlightPage({super.key, this.prefill});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;

    return BlocProvider(
      create: (context) {
        final bloc = FlightSearchBloc();
        if (prefill != null) {
          bloc.add(
            InitWithPrefilledData(
              tripId: prefill!.tripId,
              departureAirport: prefill!.originIata != null
                  ? {
                      'iataCode': prefill!.originIata,
                      'name': prefill!.originIata,
                    }
                  : null,
              arrivalAirport: prefill!.destinationIata != null
                  ? {
                      'iataCode': prefill!.destinationIata,
                      'name': prefill!.destinationIata,
                    }
                  : null,
              departureDate: prefill!.departureDate,
              returnDate: prefill!.returnDate,
              adults: prefill!.nbTravelers,
            ),
          );
        }
        return bloc;
      },
      child: Scaffold(
        backgroundColor: PersonalizationColors.gradientStartOf(brightness),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.maybePop(context),
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
          backgroundColor: PersonalizationColors.gradientStartOf(brightness),
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
