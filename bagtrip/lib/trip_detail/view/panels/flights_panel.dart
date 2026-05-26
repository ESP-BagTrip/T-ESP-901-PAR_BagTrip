import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/trip_detail/view/panels/trip_panel_empty_state.dart';
import 'package:bagtrip/core/trip_enums.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/design/widgets/flight_validation_branch_sheet.dart';
import 'package:bagtrip/design/widgets/item_status_chip.dart';
import 'package:bagtrip/design/widgets/replace_search_sheet.dart';
import 'package:bagtrip/design/widgets/review/boarding_pass_card.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/flight_search/models/flight_search_prefill.dart';
import 'package:bagtrip/flight_search/view/flight_search_form.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart'
    as result_flight;
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/design/widgets/review/sheets/quick_preview_sheet.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/models/validation_status.dart';
import 'package:bagtrip/transports/widgets/manual_flight_form.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/view/panels/skipped_panel_state.dart';
import 'package:bagtrip/trip_detail/widgets/section_error_banner.dart';
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
    this.tripStartDate,
    required this.canEdit,
    required this.isCompleted,
    required this.role,
    this.tracking = TrackingStatus.tracked,
  });

  final String tripId;
  final List<ManualFlight> flights;
  final DateTime? tripStartDate;
  final bool canEdit;
  final bool isCompleted;
  final String role;

  /// `TRACKED` (default) or `SKIPPED`. When skipped, the panel shows a
  /// stylized opt-out card instead of the list.
  final String tracking;

  Future<void> _showAddSheet(BuildContext context) async {
    final bloc = context.read<TripDetailBloc>();
    await showItemFormSheet<void>(
      context: context,
      child: ManualFlightForm(
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
    await showItemFormSheet<void>(
      context: context,
      child: ManualFlightForm(
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

  /// Phase 4 — opens the two-branch validate sheet.
  /// External branch: collects the flight number, persists it on the
  /// row, dispatches ValidateFlightFromDetail.
  /// Amadeus branch (Phase 4 FU3): hands off to the same Amadeus search
  /// flow as Replace, but in book mode — the user picks an offer and
  /// the existing flight-result-details "Book this flight" button fires
  /// CreateBookingIntent. The backend flips status=VALIDATED +
  /// source=AMADEUS_BOOKED on payment success.
  Future<void> _showValidateBranchSheet(
    BuildContext parentContext,
    ManualFlight flight,
  ) async {
    final bloc = parentContext.read<TripDetailBloc>();
    Navigator.of(parentContext).pop();
    await showFlightValidationBranchSheet<void>(
      context: parentContext,
      onPickExternal: () {
        Navigator.of(parentContext).pop();
        _showExternalNumberSheet(parentContext, flight, bloc);
      },
      onPickAmadeus: () {
        Navigator.of(parentContext).pop();
        _showFlightSearchSheet(
          parentContext,
          flight,
          mode: _FlightSearchMode.book,
        );
      },
    );
  }

  Future<void> _showExternalNumberSheet(
    BuildContext context,
    ManualFlight flight,
    TripDetailBloc bloc,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: flight.flightNumber);
    final formKey = GlobalKey<FormState>();

    Future<void> submit(BuildContext sheetContext) async {
      if (!formKey.currentState!.validate()) return;
      final number = controller.text.trim().toUpperCase();
      Navigator.of(sheetContext).pop();
      bloc.add(
        UpdateFlightFromDetail(
          flightId: flight.id,
          data: <String, dynamic>{'flightNumber': number},
        ),
      );
      bloc.add(ValidateFlightFromDetail(flightId: flight.id));
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.profileSheetBackgroundOf(
              Theme.of(sheetContext).brightness,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.cornerRadius20),
            ),
          ),
          padding: AppSpacing.allEdgeInsetSpace24,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.reviewUncheckedOf(
                        Theme.of(sheetContext).brightness,
                      ),
                      borderRadius: AppRadius.handleBar,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                Text(
                  l10n.flightValidateExternalTitle,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  l10n.flightValidateExternalSubtitle,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 13,
                    color: ColorName.hint,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                TextFormField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.flightValidateExternalNumberLabel,
                    hintText: l10n.flightValidateExternalNumberHint,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10n.flightNumberRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.space16),
                FilledButton(
                  onPressed: () => submit(sheetContext),
                  child: Text(l10n.activityValidateAction),
                ),
                const SizedBox(height: AppSpacing.space16),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
  }

  /// Phase 4 follow-up — opens the Amadeus search inside a
  /// ReplaceSearchSheet, prefilled with the flight's IATAs and the
  /// trip dates. The downstream behaviour depends on [mode]:
  ///
  /// - [_FlightSearchMode.replace] : the result page short-circuits the
  ///   details navigation (replaceFlightId carries through), the user
  ///   picks an offer, and we dispatch ReplaceFlightFromDetail (atomic
  ///   DELETE+CREATE).
  /// - [_FlightSearchMode.book] : standard flow — picking an offer
  ///   pushes flight_result_details where the existing "Book this
  ///   flight" CTA fires CreateBookingIntent. Backend flips the
  ///   row to VALIDATED + source=AMADEUS_BOOKED on payment success.
  Future<void> _showFlightSearchSheet(
    BuildContext parentContext,
    ManualFlight flight, {
    required _FlightSearchMode mode,
  }) async {
    final l10n = AppLocalizations.of(parentContext)!;
    if (mode == _FlightSearchMode.replace) {
      // The replace path is reached from the QuickPreviewSheet which
      // is still on top — drop it before stacking the search sheet.
      Navigator.of(parentContext).pop();
    }

    final prefill = FlightSearchPrefill(
      tripId: tripId,
      originIata: flight.departureAirport,
      destinationIata: flight.arrivalAirport,
      departureDate: flight.departureDate,
      returnDate: flight.arrivalDate,
      nbTravelers: 1,
    );

    final title = mode == _FlightSearchMode.replace
        ? l10n.activityValidateAction
        : l10n.flightValidateAmadeusTitle;

    await showReplaceSearchSheet<void>(
      context: parentContext,
      sheet: ReplaceSearchSheet(
        title: title,
        subtitle:
            '${flight.departureAirport ?? '?'} → ${flight.arrivalAirport ?? '?'}',
        child: BlocProvider(
          create: (_) => FlightSearchBloc()
            ..add(
              InitWithPrefilledData(
                tripId: prefill.tripId,
                departureAirport: prefill.originIata != null
                    ? {
                        'iataCode': prefill.originIata,
                        'name': prefill.originIata,
                      }
                    : null,
                arrivalAirport: prefill.destinationIata != null
                    ? {
                        'iataCode': prefill.destinationIata,
                        'name': prefill.destinationIata,
                      }
                    : null,
                departureDate: prefill.departureDate,
                returnDate: prefill.returnDate,
                adults: prefill.nbTravelers,
              ),
            ),
          child: FlightSearchForm(
            onSubmit: (args) async {
              Navigator.of(parentContext).pop();
              if (mode == _FlightSearchMode.replace) {
                // Replace mode: the result widget pops with the picked
                // Flight (skipping the details push when replaceFlightId
                // is set) so we can dispatch the atomic replace.
                final withReplaceId = args.copyWith(replaceFlightId: flight.id);
                final picked = await FlightSearchResultRoute(
                  $extra: withReplaceId,
                ).push<result_flight.Flight>(parentContext);
                if (picked == null || !parentContext.mounted) return;
                parentContext.read<TripDetailBloc>().add(
                  ReplaceFlightFromDetail(
                    oldFlightId: flight.id,
                    newFlightData: _flightToManualPayload(picked, flight),
                  ),
                );
              } else {
                // Book mode: no replaceFlightId, the result widget
                // navigates to flight_result_details where the existing
                // CreateBookingIntent button takes over. Backend flips
                // the underlying ManualFlight to VALIDATED on payment.
                FlightSearchResultRoute($extra: args).push(parentContext);
              }
            },
          ),
        ),
      ),
    );
  }

  /// Convenience wrapper preserved for [_showPreview] which only knows
  /// about replace; the validate-branch sheet calls
  /// [_showFlightSearchSheet] directly with [_FlightSearchMode.book].
  Future<void> _showReplaceSheet(
    BuildContext parentContext,
    ManualFlight flight,
  ) => _showFlightSearchSheet(
    parentContext,
    flight,
    mode: _FlightSearchMode.replace,
  );

  Future<void> _showPreview(BuildContext context, ManualFlight flight) async {
    final l10n = AppLocalizations.of(context)!;
    AppHaptics.light();
    final subtitle = flight.flightType == 'RETURN'
        ? l10n.reviewFlightReturn
        : l10n.reviewFlightOutbound;
    final isSuggested = flight.validationStatus == ValidationStatus.suggested;
    await showQuickPreviewSheet(
      context: context,
      icon: Icons.flight_takeoff_rounded,
      title: _titleFor(flight),
      subtitle: subtitle,
      body: _FlightPreviewBody(flight: flight),
      // Phase 4 — three-action preview sheet:
      //   Validate (branche externe / Amadeus) — when the flight is
      //   SUGGESTED and editable.
      //   Replace (search Amadeus inline) — re-key the row from a
      //   different offer with a single atomic DELETE+CREATE handler.
      //   Delete (destructive) — unchanged.
      // Edit stays accessible via long-press on the card (context menu).
      validateAction: isSuggested && canEdit
          ? QuickPreviewAction(
              label: l10n.activityValidateAction,
              icon: Icons.check_rounded,
              onPressed: () => _showValidateBranchSheet(context, flight),
            )
          : null,
      primaryAction: canEdit
          ? QuickPreviewAction(
              label: l10n.flightValidateAmadeusTitle,
              icon: Icons.swap_horiz_rounded,
              onPressed: () => _showReplaceSheet(context, flight),
            )
          : null,
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
    return Column(
      children: [
        const SectionErrorBanner(section: 'flights'),
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
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
            TripPanelEmptyState(
              icon: Icons.flight_takeoff_rounded,
              title: l10n.emptyFlightsTitle,
              ctaLabel: l10n.emptyFlightsAddNow,
              tripStartDate: tripStartDate,
              canEdit: canEdit,
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
          itemCount: sortedFlights.length + (canEdit ? 1 : 0),
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.space16),
          itemBuilder: (context, index) {
            if (canEdit && index == sortedFlights.length) {
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
            final boardingPass = BoardingPassCard(
              title: _flightTitle(flight, l10n),
              flight: _toBoardingPassModel(flight, l10n, locale),
              onTap: () => _showPreview(context, flight),
            );
            // Phase 1 — material truth: a SUGGESTED flight wears a halo
            // chip so the user knows it's awaiting their review.
            // VALIDATED + MANUAL stay chip-free to keep the list calm.
            final card = flight.validationStatus == ValidationStatus.suggested
                ? Stack(
                    children: [
                      boardingPass,
                      const Positioned(
                        top: AppSpacing.space8,
                        right: AppSpacing.space8,
                        child: ItemStatusChip(
                          kind: ItemStatusChipKind.suggested,
                        ),
                      ),
                    ],
                  )
                : boardingPass;
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

/// Phase 4 FU3 — distinguishes the two intents that share the Amadeus
/// search UI from the trip-detail panel.
enum _FlightSearchMode { replace, book }

/// Maps an Amadeus search-result Flight to the ManualFlight create payload
/// used by [TransportRepository.createManualFlight]. Reuses the original
/// flight's [flightType] so a MAIN replacement stays MAIN, etc. The Amadeus
/// offer has no straightforward "flight number" (its id is an offer id);
/// we fall back to that until the user edits the row.
Map<String, dynamic> _flightToManualPayload(
  result_flight.Flight picked,
  ManualFlight original,
) {
  return <String, dynamic>{
    'flightNumber': picked.id,
    if (picked.airline != null) 'airline': picked.airline,
    'departureAirport': picked.departureAirport,
    'arrivalAirport': picked.arrivalAirport,
    if (picked.departureDateTime != null)
      'departureDate': picked.departureDateTime!.toIso8601String(),
    if (picked.arrivalDateTime != null)
      'arrivalDate': picked.arrivalDateTime!.toIso8601String(),
    'price': picked.price,
    'flightType': original.flightType,
  };
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
