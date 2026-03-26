import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/transports/bloc/transport_bloc.dart';
import 'package:bagtrip/transports/widgets/add_flight_sheet.dart';
import 'package:bagtrip/transports/widgets/flight_card.dart';
import 'package:bagtrip/transports/widgets/main_flights_section.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransportsView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOwner = role == 'OWNER';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transportsTitle),
        actions: [
          if (isOwner && !isCompleted && AdaptivePlatform.isIOS)
            IconButton(
              icon: const Icon(CupertinoIcons.add),
              tooltip: l10n.addTransportTooltip,
              onPressed: () => _showAddSheet(context),
            ),
        ],
      ),
      body: BlocConsumer<TransportBloc, TransportState>(
        listener: (context, state) {
          if (state is TransportError) {
            AppSnackBar.showError(
              context,
              message: toUserFriendlyMessage(state.error, l10n),
            );
            context.read<TransportBloc>().add(LoadTransports(tripId: tripId));
          }
        },
        builder: (context, state) {
          if (state is TransportLoading) {
            return const LoadingView();
          }

          if (state is TransportError) {
            return ErrorView(
              message: toUserFriendlyMessage(state.error, l10n),
              onRetry: () => context.read<TransportBloc>().add(
                LoadTransports(tripId: tripId),
              ),
            );
          }

          if (state is TransportsLoaded) {
            if (state.transports.isEmpty) {
              return _EmptyState(
                onAdd: isOwner && !isCompleted
                    ? () => _showAddSheet(context)
                    : null,
              );
            }

            return CustomScrollView(
              slivers: [
                if (state.mainFlights.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space24,
                        AppSpacing.space16,
                        AppSpacing.space24,
                        AppSpacing.space8,
                      ),
                      child: Text(
                        l10n.mainFlightsSection,
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                if (state.mainFlights.isNotEmpty)
                  SliverToBoxAdapter(
                    child: MainFlightsSection(
                      flights: state.mainFlights,
                      onDelete: isOwner && !isCompleted
                          ? (id) => context.read<TransportBloc>().add(
                              DeleteManualFlight(tripId: tripId, flightId: id),
                            )
                          : null,
                    ),
                  ),
                if (state.internalFlights.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space24,
                        AppSpacing.space24,
                        AppSpacing.space24,
                        AppSpacing.space8,
                      ),
                      child: Text(
                        l10n.internalFlightsSection,
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: AppSpacing.horizontalSpace24,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final flight = state.internalFlights[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.space12,
                          ),
                          child: FlightCard(
                            flight: flight,
                            compact: true,
                            onDelete: isOwner && !isCompleted
                                ? () => context.read<TransportBloc>().add(
                                    DeleteManualFlight(
                                      tripId: tripId,
                                      flightId: flight.id,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }, childCount: state.internalFlights.length),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: isOwner && !isCompleted && !AdaptivePlatform.isIOS
          ? BlocBuilder<TransportBloc, TransportState>(
              builder: (context, state) {
                if (state is TransportsLoaded && state.transports.isEmpty) {
                  return const SizedBox.shrink();
                }
                return FloatingActionButton.extended(
                  onPressed: () => _showAddSheet(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addFlight),
                );
              },
            )
          : null,
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TransportBloc>(),
        child: AddFlightSheet(tripId: tripId, parentContext: context),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onAdd;

  const _EmptyState({this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ElegantEmptyState(
      icon: Icons.flight_takeoff_rounded,
      title: l10n.emptyTransportsTitle,
      subtitle: l10n.emptyTransportsSubtitle,
      ctaLabel: onAdd != null ? l10n.addFlight : null,
      onCta: onAdd,
    );
  }
}
