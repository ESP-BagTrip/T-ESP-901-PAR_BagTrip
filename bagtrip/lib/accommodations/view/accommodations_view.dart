import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/widgets/accommodation_card.dart';
import 'package:bagtrip/accommodations/widgets/add_accommodation_sheet.dart';
import 'package:bagtrip/accommodations/widgets/ai_suggestions_sheet.dart';
import 'package:bagtrip/accommodations/widgets/manual_accommodation_form.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccommodationsView extends StatelessWidget {
  final String tripId;
  final String role;
  final bool isCompleted;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;
  final String? destinationIata;

  const AccommodationsView({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
    this.tripStartDate,
    this.tripEndDate,
    this.destinationIata,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canEdit = role != 'VIEWER' && !isCompleted;

    return MultiBlocListener(
      listeners: [
        BlocListener<AccommodationBloc, AccommodationState>(
          listenWhen: (_, current) => current is AccommodationQuotaExceeded,
          listener: (context, _) => PremiumPaywall.show(context),
        ),
        BlocListener<AccommodationBloc, AccommodationState>(
          listenWhen: (_, current) => current is AccommodationSuggestionsLoaded,
          listener: (context, state) {
            if (state is AccommodationSuggestionsLoaded) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: context.read<AccommodationBloc>(),
                  child: AiSuggestionsSheet(
                    tripId: tripId,
                    suggestions: state.suggestions,
                  ),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.accommodationsTitle),
          actions: [
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: l10n.accommodationAiSuggestTitle,
                onPressed: () {
                  context.read<AccommodationBloc>().add(
                    SuggestAccommodations(tripId: tripId),
                  );
                },
              ),
            if (canEdit && AdaptivePlatform.isIOS)
              IconButton(
                icon: const Icon(CupertinoIcons.add),
                tooltip: l10n.addAccommodationTooltip,
                onPressed: () => _showAddSheet(context),
              ),
          ],
        ),
        body: BlocBuilder<AccommodationBloc, AccommodationState>(
          builder: (context, state) {
            if (state is AccommodationLoading ||
                state is AccommodationSuggestionsLoading) {
              return const LoadingView();
            }
            if (state is AccommodationError) {
              return ErrorView(
                message: toUserFriendlyMessage(state.error, l10n),
                onRetry: () => context.read<AccommodationBloc>().add(
                  LoadAccommodations(tripId: tripId),
                ),
              );
            }
            if (state is AccommodationsLoaded) {
              final accommodations = state.accommodations;
              if (accommodations.isEmpty) {
                return ElegantEmptyState(
                  icon: Icons.hotel_outlined,
                  title: l10n.emptyAccommodationsTitle,
                  subtitle: l10n.emptyAccommodationsSubtitle,
                );
              }
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: AppSpacing.allEdgeInsetSpace16,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final accommodation = accommodations[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.space12,
                          ),
                          child: AccommodationCard(
                            accommodation: accommodation,
                            isViewer: !canEdit,
                            onEdit: canEdit
                                ? () {
                                    final bloc = context
                                        .read<AccommodationBloc>();
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => BlocProvider.value(
                                        value: bloc,
                                        child: ManualAccommodationForm(
                                          tripId: tripId,
                                          existing: accommodation,
                                          tripStartDate: tripStartDate,
                                          tripEndDate: tripEndDate,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            onDelete: canEdit
                                ? () {
                                    context.read<AccommodationBloc>().add(
                                      DeleteAccommodation(
                                        tripId: tripId,
                                        accommodationId: accommodation.id,
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        );
                      }, childCount: accommodations.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: canEdit && !AdaptivePlatform.isIOS
            ? FloatingActionButton.extended(
                onPressed: () => _showAddSheet(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.accommodationAddTitle),
              )
            : null,
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AccommodationBloc>(),
        child: AddAccommodationSheet(
          tripId: tripId,
          tripStartDate: tripStartDate,
          tripEndDate: tripEndDate,
          destinationIata: destinationIata,
        ),
      ),
    );
  }
}
