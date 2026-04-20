import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/boarding_pass_card.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Flights tab of the new [TripDetailView].
///
/// Renders one [BoardingPassCard] per [ManualFlight]. Tapping a card routes
/// to the full `/transports` page for edit, swipe-to-delete dispatches
/// `DeleteFlightFromDetail` (optimistic via the bloc).
class FlightsPanel extends StatelessWidget {
  const FlightsPanel({
    super.key,
    required this.tripId,
    required this.flights,
    required this.canEdit,
    required this.isCompleted,
    required this.role,
  });

  final String tripId;
  final List<ManualFlight> flights;
  final bool canEdit;
  final bool isCompleted;
  final String role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (flights.isEmpty) {
      return _EmptyFlights(
        canEdit: canEdit,
        onAdd: () => _openTransports(context),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space24,
      ),
      itemCount: flights.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space16),
      itemBuilder: (context, index) {
        final flight = flights[index];
        final card = BoardingPassCard(
          title: _flightTitle(flight, l10n),
          flight: _toBoardingPassModel(flight, l10n, locale),
          onTap: canEdit ? () => _openTransports(context) : null,
        );
        if (!canEdit) return card;
        return Dismissible(
          key: ValueKey('flight-${flight.id}'),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          confirmDismiss: (_) async {
            AppHaptics.medium();
            return true;
          },
          onDismissed: (_) {
            context.read<TripDetailBloc>().add(
              DeleteFlightFromDetail(flightId: flight.id),
            );
          },
          child: card,
        );
      },
    );
  }

  void _openTransports(BuildContext context) {
    TransportsRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
    ).push(context);
  }

  String _flightTitle(ManualFlight flight, AppLocalizations l10n) {
    if (flight.flightType == 'RETURN') return l10n.reviewFlightReturn;
    return l10n.reviewFlightOutbound;
  }

  BoardingPassModel _toBoardingPassModel(
    ManualFlight flight,
    AppLocalizations l10n,
    String locale,
  ) {
    final origin = flight.departureAirport?.isNotEmpty == true
        ? flight.departureAirport!
        : '---';
    final destination = flight.arrivalAirport?.isNotEmpty == true
        ? flight.arrivalAirport!
        : '---';
    final departure = _formatTime(flight.departureDate);
    final arrival = _formatTime(flight.arrivalDate);
    final flightDate = _formatDate(flight.departureDate, locale);
    final airlineLine = [
      if (flight.airline != null && flight.airline!.isNotEmpty) flight.airline!,
      flight.flightNumber,
      flight.flightType == 'RETURN'
          ? l10n.reviewFlightReturn
          : l10n.reviewFlightOutbound,
    ].join(' · ');
    return BoardingPassModel(
      origin: origin,
      destination: destination,
      subtitle: flight.notes ?? '',
      departure: departure,
      arrival: arrival,
      airlineLine: airlineLine,
      flightDate: flightDate,
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('HH:mm').format(dt);
  }

  String _formatDate(DateTime? dt, String locale) {
    if (dt == null) return '';
    return DateFormat('EEEE d MMM yyyy', locale).format(dt);
  }
}

class _EmptyFlights extends StatelessWidget {
  const _EmptyFlights({required this.canEdit, required this.onAdd});

  final bool canEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space24),
      child: ElegantEmptyState(
        icon: Icons.flight_takeoff_rounded,
        title: l10n.emptyFlightsTitle,
        subtitle: canEdit ? l10n.emptyFlightsSubtitle : null,
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      decoration: const BoxDecoration(
        color: ColorName.error,
        borderRadius: AppRadius.large16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
