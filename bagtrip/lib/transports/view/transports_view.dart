import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/boarding_pass_card.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/sub_page_hero.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/transports/bloc/transport_bloc.dart';
import 'package:bagtrip/transports/widgets/manual_flight_form.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TransportsView extends StatefulWidget {
  final String tripId;
  final String role;
  final bool isCompleted;

  const TransportsView({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  @override
  State<TransportsView> createState() => _TransportsViewState();
}

class _TransportsViewState extends State<TransportsView>
    with TickerProviderStateMixin {
  late final PanelFooterCtaController _footerController;

  @override
  void initState() {
    super.initState();
    _footerController = PanelFooterCtaController(vsync: this);
    _footerController.show();
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  bool get _canEdit => widget.role == 'OWNER' && !widget.isCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: ColorName.surfaceVariant,
      body: Column(
        children: [
          SubPageHero(title: l10n.transportsTitle),
          Expanded(
            child: BlocConsumer<TransportBloc, TransportState>(
              listener: (context, state) {
                if (state is TransportError) {
                  AppSnackBar.showError(
                    context,
                    message: toUserFriendlyMessage(state.error, l10n),
                  );
                  context.read<TransportBloc>().add(
                    LoadTransports(tripId: widget.tripId),
                  );
                } else if (state is TransportsLoaded) {
                  context.read<TripDetailBloc>().add(RefreshTripDetail());
                }
              },
              builder: (context, state) {
                if (state is TransportLoading) return const LoadingView();
                if (state is TransportError) {
                  return ErrorView(
                    message: toUserFriendlyMessage(state.error, l10n),
                    onRetry: () => context.read<TransportBloc>().add(
                      LoadTransports(tripId: widget.tripId),
                    ),
                  );
                }
                if (state is! TransportsLoaded) return const SizedBox.shrink();
                if (state.transports.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.space24),
                    child: ElegantEmptyState(
                      icon: Icons.flight_takeoff_rounded,
                      title: l10n.emptyTransportsTitle,
                      subtitle: _canEdit ? l10n.emptyTransportsSubtitle : null,
                    ),
                  );
                }

                final locale = Localizations.localeOf(context).languageCode;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    AppSpacing.space16,
                    AppSpacing.space16,
                    AppSpacing.space32 + 72,
                  ),
                  children: [
                    if (state.mainFlights.isNotEmpty) ...[
                      _SectionLabel(text: l10n.mainFlightsSection),
                      const SizedBox(height: AppSpacing.space12),
                      ...state.mainFlights.map(
                        (f) => _FlightRow(
                          flight: f,
                          canEdit: _canEdit,
                          locale: locale,
                          onEdit: () => _showEditSheet(context, f),
                          onDelete: () => _deleteFlight(context, f.id),
                        ),
                      ),
                    ],
                    if (state.internalFlights.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space16),
                      _SectionLabel(text: l10n.internalFlightsSection),
                      const SizedBox(height: AppSpacing.space12),
                      ...state.internalFlights.map(
                        (f) => _FlightRow(
                          flight: f,
                          canEdit: _canEdit,
                          locale: locale,
                          onEdit: () => _showEditSheet(context, f),
                          onDelete: () => _deleteFlight(context, f.id),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _canEdit
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space8,
                  AppSpacing.space16,
                  AppSpacing.space16,
                ),
                child: PanelFooterCta(
                  controller: _footerController,
                  child: PillCtaButton(
                    label: l10n.addFlight,
                    leadingIcon: Icons.add_rounded,
                    onTap: () => _showAddSheet(context),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _deleteFlight(BuildContext context, String flightId) {
    AppHaptics.medium();
    context.read<TransportBloc>().add(
      DeleteManualFlight(tripId: widget.tripId, flightId: flightId),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TransportBloc>(),
        child: _FormWrapper(child: ManualFlightForm(tripId: widget.tripId)),
      ),
    );
  }

  void _showEditSheet(BuildContext context, ManualFlight flight) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TransportBloc>(),
        child: _FormWrapper(
          child: ManualFlightForm(tripId: widget.tripId, existing: flight),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: FontFamily.dMSans,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: ColorName.hint,
      ),
    );
  }
}

class _FlightRow extends StatelessWidget {
  const _FlightRow({
    required this.flight,
    required this.canEdit,
    required this.locale,
    required this.onEdit,
    required this.onDelete,
  });

  final ManualFlight flight;
  final bool canEdit;
  final String locale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final card = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space12),
      child: BoardingPassCard(
        title: _title(l10n),
        flight: _toModel(l10n),
        onTap: canEdit ? onEdit : null,
      ),
    );
    if (!canEdit) return card;
    return Dismissible(
      key: ValueKey('transport-${flight.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space24),
        decoration: BoxDecoration(
          color: ColorName.error.withValues(alpha: 0.9),
          borderRadius: AppRadius.large16,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.space12),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: card,
    );
  }

  String _title(AppLocalizations l10n) {
    if (flight.flightType == 'RETURN') return l10n.reviewFlightReturn;
    if (flight.flightType == 'INTERNAL') {
      return l10n.internalFlightsSection.toUpperCase();
    }
    return l10n.reviewFlightOutbound;
  }

  BoardingPassModel _toModel(AppLocalizations l10n) {
    final origin = flight.departureAirport?.isNotEmpty == true
        ? flight.departureAirport!
        : '---';
    final destination = flight.arrivalAirport?.isNotEmpty == true
        ? flight.arrivalAirport!
        : '---';
    return BoardingPassModel(
      origin: origin,
      destination: destination,
      subtitle: flight.notes ?? '',
      departure: _formatTime(flight.departureDate),
      arrival: _formatTime(flight.arrivalDate),
      airlineLine: [
        if (flight.airline != null && flight.airline!.isNotEmpty)
          flight.airline!,
        flight.flightNumber,
      ].join(' · '),
      flightDate: _formatDate(flight.departureDate),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('HH:mm').format(dt);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('EEEE d MMM yyyy', locale).format(dt);
  }
}

class _FormWrapper extends StatelessWidget {
  const _FormWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.cornerRadius24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.space12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorName.hint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
