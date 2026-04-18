import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/core/trip_enums.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/boarding_pass_card.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/design/widgets/review/sheets/quick_preview_sheet.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/transports/widgets/manual_flight_form.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/view/panels/skipped_panel_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Flights tab — tap to preview, long-press for context menu, swipe to
/// delete, `+` FAB to add. Navigation to `/transports` is opt-in via the
/// "See all flights" footer or the preview sheet's "Open full" action.
class FlightsPanel extends StatelessWidget {
  const FlightsPanel({
    super.key,
    required this.tripId,
    required this.flights,
    required this.canEdit,
    required this.isCompleted,
    required this.role,
    this.tracking = TrackingStatus.tracked,
  });

  final String tripId;
  final List<ManualFlight> flights;
  final bool canEdit;
  final bool isCompleted;
  final String role;

  /// `TRACKED` (default) or `SKIPPED`. When skipped, the panel shows a
  /// stylized opt-out card instead of the list.
  final String tracking;

  void _openFullPage(BuildContext context) {
    TransportsRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
    ).push(context);
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final bloc = context.read<TripDetailBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualFlightForm(
        tripId: tripId,
        onSave: (data) {
          AppHaptics.medium();
          bloc.add(CreateFlightFromDetail(data: data));
        },
      ),
    );
  }

  Future<void> _showEditSheet(BuildContext context, ManualFlight flight) async {
    final bloc = context.read<TripDetailBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualFlightForm(
        tripId: tripId,
        existing: flight,
        onSave: (data) {
          AppHaptics.medium();
          bloc.add(UpdateFlightFromDetail(flightId: flight.id, data: data));
        },
      ),
    );
  }

  void _delete(BuildContext context, ManualFlight flight) {
    AppHaptics.medium();
    context.read<TripDetailBloc>().add(
      DeleteFlightFromDetail(flightId: flight.id),
    );
  }

  Future<void> _showPreview(BuildContext context, ManualFlight flight) async {
    final l10n = AppLocalizations.of(context)!;
    AppHaptics.light();
    final subtitle = flight.flightType == 'RETURN'
        ? l10n.reviewFlightReturn
        : l10n.reviewFlightOutbound;
    await showQuickPreviewSheet(
      context: context,
      icon: Icons.flight_takeoff_rounded,
      title: _titleFor(flight),
      subtitle: subtitle,
      body: _FlightPreviewBody(flight: flight),
      primaryAction: canEdit
          ? QuickPreviewAction(
              label: l10n.panelActionEdit,
              icon: Icons.edit_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _showEditSheet(context, flight);
              },
            )
          : QuickPreviewAction(
              label: l10n.panelOpenFullFlights,
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _openFullPage(context);
              },
            ),
      destructiveAction: canEdit
          ? QuickPreviewAction(
              label: l10n.panelActionDelete,
              icon: Icons.delete_outline_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _delete(context, flight);
              },
              isDestructive: true,
            )
          : null,
      openFullLabel: l10n.panelOpenFullFlights,
      onOpenFull: () => _openFullPage(context),
    );
  }

  String _titleFor(ManualFlight flight) {
    final from = flight.departureAirport ?? '---';
    final to = flight.arrivalAirport ?? '---';
    return '$from → $to';
  }

  List<ManualFlight> _sorted(List<ManualFlight> list) {
    final sorted = [...list]
      ..sort((a, b) {
        final aDate = a.departureDate ?? DateTime(3000);
        final bDate = b.departureDate ?? DateTime(3000);
        return aDate.compareTo(bDate);
      });
    return sorted;
  }

  void _toggleTracking(BuildContext context, {required bool skip}) {
    AppHaptics.medium();
    context.read<TripDetailBloc>().add(
      UpdateTripTrackingFromDetail(
        flightsTracking: skip ? TrackingStatus.skipped : TrackingStatus.tracked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (tracking == TrackingStatus.skipped) {
      return SkippedPanelState(
        title: l10n.panelSkippedFlightsTitle,
        message: l10n.panelSkippedFlightsMessage,
        resumeLabel: l10n.panelResumeFlightsCta,
        onResume: canEdit ? () => _toggleTracking(context, skip: false) : null,
      );
    }
    if (flights.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElegantEmptyState(
              icon: Icons.flight_takeoff_rounded,
              title: l10n.emptyFlightsTitle,
              subtitle: canEdit ? l10n.emptyFlightsSubtitle : null,
              ctaLabel: canEdit ? l10n.panelQuickAddFlight : null,
              onCta: canEdit ? () => _showAddSheet(context) : null,
            ),
            if (canEdit) ...[
              const SizedBox(height: AppSpacing.space16),
              TextButton(
                onPressed: () => _toggleTracking(context, skip: true),
                child: Text(
                  l10n.panelSkipFlightsCta,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    color: ColorName.hint,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    final sortedFlights = _sorted(flights);

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space56 + AppSpacing.space40,
          ),
          itemCount: sortedFlights.length + (canEdit ? 2 : 1),
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.space16),
          itemBuilder: (context, index) {
            if (index == sortedFlights.length) {
              return Center(
                child: TextButton(
                  onPressed: () => _openFullPage(context),
                  child: Text(
                    l10n.panelOpenFullFlights,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ColorName.hint,
                    ),
                  ),
                ),
              );
            }
            if (canEdit && index == sortedFlights.length + 1) {
              return Center(
                child: TextButton(
                  onPressed: () => _toggleTracking(context, skip: true),
                  child: Text(
                    l10n.panelSkipFlightsCta,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      color: ColorName.hint,
                    ),
                  ),
                ),
              );
            }
            final flight = sortedFlights[index];
            final card = BoardingPassCard(
              title: _flightTitle(flight, l10n),
              flight: _toBoardingPassModel(flight, l10n, locale),
              onTap: () => _showPreview(context, flight),
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
              onDismissed: (_) => _delete(context, flight),
              child: AdaptiveContextMenu(
                actions: [
                  AdaptiveContextAction(
                    label: l10n.panelActionEdit,
                    icon: Icons.edit_outlined,
                    onPressed: () => _showEditSheet(context, flight),
                  ),
                  AdaptiveContextAction(
                    label: l10n.panelActionDelete,
                    icon: Icons.delete_outline_rounded,
                    onPressed: () => _delete(context, flight),
                    isDestructive: true,
                  ),
                ],
                child: card,
              ),
            );
          },
        ),
        if (canEdit)
          Positioned(
            bottom: AppSpacing.space24,
            right: AppSpacing.space24,
            child: PanelFab(
              label: l10n.panelQuickAddFlight,
              onTap: () => _showAddSheet(context),
            ),
          ),
      ],
    );
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

class _FlightPreviewBody extends StatelessWidget {
  const _FlightPreviewBody({required this.flight});

  final ManualFlight flight;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final fmtDateTime = DateFormat('EEE d MMM · HH:mm', locale);
    final rows = <_DetailRow>[
      if (flight.flightNumber.isNotEmpty)
        _DetailRow(label: 'FLIGHT', value: flight.flightNumber),
      if (flight.airline != null && flight.airline!.isNotEmpty)
        _DetailRow(label: 'AIRLINE', value: flight.airline!),
      if (flight.departureDate != null)
        _DetailRow(
          label: 'DEPARTURE',
          value: fmtDateTime.format(flight.departureDate!),
        ),
      if (flight.arrivalDate != null)
        _DetailRow(
          label: 'ARRIVAL',
          value: fmtDateTime.format(flight.arrivalDate!),
        ),
      if (flight.price != null)
        _DetailRow(label: 'PRICE', value: flight.price!.toStringAsFixed(2)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space12),
          rows[i],
        ],
        if (flight.notes != null && flight.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space16),
          Text(
            flight.notes!,
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 13,
              height: 1.5,
              color: ColorName.primaryDark,
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: ColorName.hint,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 15,
              color: ColorName.primaryDark,
            ),
          ),
        ),
      ],
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
