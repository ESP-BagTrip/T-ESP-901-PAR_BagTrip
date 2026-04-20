import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/subpage_state.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/animated_count.dart';
import 'package:bagtrip/design/widgets/review/blank_canvas_hero.dart';
import 'package:bagtrip/design/widgets/review/boarding_pass_card.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/state_responsive_hero.dart';
import 'package:bagtrip/design/widgets/review/tap_scale_aware.dart';
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
      body: BlocConsumer<TransportBloc, TransportState>(
        listener: (context, state) {
          if (state is TransportError) {
            AppSnackBar.showError(
              context,
              message: toUserFriendlyMessage(state.error, l10n),
            );
          } else if (state is TransportsLoaded) {
            context.read<TripDetailBloc>().add(RefreshTripDetail());
          }
        },
        builder: (context, state) {
          final isLoading = state is TransportLoading;
          final hasError = state is TransportError;
          final flights = state is TransportsLoaded
              ? state.transports
              : const <ManualFlight>[];
          final screenState = resolveSubpageState(
            isLoading: isLoading,
            hasError: hasError,
            count: flights.length,
            canEdit: _canEdit,
            isCompleted: widget.isCompleted,
          );

          switch (screenState) {
            case SubpageScreenState.booting:
              return const LoadingView();
            case SubpageScreenState.error:
              return ErrorView(
                message: toUserFriendlyMessage(
                  (state as TransportError).error,
                  l10n,
                ),
                onRetry: () => context.read<TransportBloc>().add(
                  LoadTransports(tripId: widget.tripId),
                ),
              );
            case SubpageScreenState.blankCanvas:
              return _buildBlankCanvas(context, l10n);
            case SubpageScreenState.sparse:
            case SubpageScreenState.dense:
            case SubpageScreenState.viewer:
            case SubpageScreenState.archive:
              final density = densityOf(screenState)!;
              return _buildPopulated(
                context,
                l10n,
                state as TransportsLoaded,
                screenState,
                density,
              );
          }
        },
      ),
    );
  }

  Widget _buildBlankCanvas(BuildContext context, AppLocalizations l10n) {
    return BlankCanvasHero(
      icon: Icons.flight_takeoff_rounded,
      title: l10n.blankTransportsTitle,
      subtitle: l10n.blankTransportsSubtitle,
      primaryLabel: l10n.blankTransportsPrimary,
      primaryLeadingIcon: Icons.add_rounded,
      onPrimary: () {
        AppHaptics.medium();
        _showAddSheet(context);
      },
      breathingIconBuilder: BlankCanvasBreathing.tilt(),
    );
  }

  Widget _buildPopulated(
    BuildContext context,
    AppLocalizations l10n,
    TransportsLoaded state,
    SubpageScreenState screenState,
    HeroDensity density,
  ) {
    final isViewer = screenState == SubpageScreenState.viewer;
    final isArchive = screenState == SubpageScreenState.archive;
    final interactive = !isViewer && !isArchive;
    final locale = Localizations.localeOf(context).languageCode;

    final children = <Widget>[];
    if (state.mainFlights.isNotEmpty) {
      children.add(_SectionLabel(text: l10n.mainFlightsSection));
      for (final f in state.mainFlights) {
        children.add(
          _FlightRow(
            flight: f,
            canEdit: interactive,
            locale: locale,
            onEdit: () => _showEditSheet(context, f),
            onDelete: () => _deleteFlight(context, f.id),
          ),
        );
      }
    }
    if (state.internalFlights.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.space16));
      }
      children.add(_SectionLabel(text: l10n.internalFlightsSection));
      for (final f in state.internalFlights) {
        children.add(
          _FlightRow(
            flight: f,
            canEdit: interactive,
            locale: locale,
            onEdit: () => _showEditSheet(context, f),
            onDelete: () => _deleteFlight(context, f.id),
          ),
        );
      }
    }

    final body = ListView(
      padding: EdgeInsets.only(
        left: density == HeroDensity.sparse ? 24 : 12,
        right: density == HeroDensity.sparse ? 24 : 12,
        top: density == HeroDensity.sparse ? 24 : 12,
        bottom:
            (density == HeroDensity.sparse ? 24 : 12) + (interactive ? 96 : 24),
      ),
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1)
            SizedBox(
              height: density == HeroDensity.sparse
                  ? AppSpacing.space16
                  : AppSpacing.space8,
            ),
        ],
      ],
    );

    return Column(
      children: [
        StateResponsiveHero(
          title: l10n.transportsTitle,
          density: density,
          meta: AnimatedCount(
            value: state.transports.length,
            formatter: l10n.transportsHeroMeta,
          ),
          badge: isViewer
              ? HeroBadge(label: l10n.subpageHeroBadgeViewer)
              : isArchive
              ? HeroBadge(
                  label: l10n.subpageHeroBadgeCompleted,
                  tone: HeroBadgeTone.success,
                )
              : null,
        ),
        Expanded(
          child: ScrollReactiveCtaScaffold(
            controller: _footerController,
            body: body,
            footer: interactive
                ? PillCtaButton(
                    label: l10n.addFlight,
                    leadingIcon: Icons.add_rounded,
                    onTap: () {
                      AppHaptics.medium();
                      _showAddSheet(context);
                    },
                  )
                : null,
          ),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: ColorName.hint,
        ),
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
    final card = BoardingPassCard(title: _title(l10n), flight: _toModel());
    if (!canEdit) return card;
    final tappable = TapScaleAware(
      onTap: () {
        AppHaptics.light();
        onEdit();
      },
      child: card,
    );
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
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: tappable,
    );
  }

  String _title(AppLocalizations l10n) {
    if (flight.flightType == 'RETURN') return l10n.reviewFlightReturn;
    if (flight.flightType == 'INTERNAL') {
      return l10n.internalFlightsSection.toUpperCase();
    }
    return l10n.reviewFlightOutbound;
  }

  BoardingPassModel _toModel() {
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
