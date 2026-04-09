import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/baggage/widgets/baggage_add_form.dart';
import 'package:bagtrip/baggage/widgets/baggage_edit_form.dart';
import 'package:bagtrip/baggage/widgets/baggage_celebration.dart';
import 'package:bagtrip/baggage/widgets/baggage_item_tile.dart';
import 'package:bagtrip/baggage/widgets/baggage_progress_header.dart';
import 'package:bagtrip/baggage/widgets/baggage_suggestion_card.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BaggageView extends StatelessWidget {
  final String tripId;
  final String role;
  final bool isCompleted;

  const BaggageView({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canEdit = role != 'VIEWER' && !isCompleted;

    return MultiBlocListener(
      listeners: [
        BlocListener<BaggageBloc, BaggageState>(
          listenWhen: (_, current) => current is BaggageQuotaExceeded,
          listener: (context, _) => PremiumPaywall.show(context),
        ),
        BlocListener<BaggageBloc, BaggageState>(
          listenWhen: (_, current) =>
              current is BaggageLoaded && current.celebrationTriggered,
          listener: (context, _) {
            AppHaptics.success();
            showDialog(
              context: context,
              barrierColor: Colors.black54,
              builder: (_) => const BaggageCelebration(),
            );
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.baggageTitle),
          actions: [
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: l10n.baggageSuggestionsTooltip,
                onPressed: () {
                  context.read<BaggageBloc>().add(
                    SuggestBaggage(tripId: tripId),
                  );
                },
              ),
            if (canEdit && AdaptivePlatform.isIOS)
              IconButton(
                icon: const Icon(CupertinoIcons.add),
                tooltip: l10n.addBaggageItemTooltip,
                onPressed: () => _showAddForm(context),
              ),
          ],
        ),
        body: BlocBuilder<BaggageBloc, BaggageState>(
          builder: (context, state) {
            if (state is BaggageLoading) {
              return const LoadingView();
            }
            if (state is BaggageError) {
              return ErrorView(
                message: toUserFriendlyMessage(state.error, l10n),
                onRetry: () => context.read<BaggageBloc>().add(
                  LoadBaggage(tripId: tripId),
                ),
              );
            }
            if (state is BaggageSuggestionsLoading) {
              return _buildContent(
                context,
                items: state.items,
                packedCount: state.packedCount,
                totalCount: state.totalCount,
                suggestions: const [],
                canEdit: canEdit,
                suggestionsLoading: true,
              );
            }
            if (state is BaggageLoaded) {
              if (state.items.isEmpty && state.suggestions.isEmpty) {
                return ElegantEmptyState(
                  icon: Icons.luggage_outlined,
                  title: l10n.emptyBaggageTitle,
                  subtitle: l10n.emptyBaggageSubtitle,
                );
              }
              return _buildContent(
                context,
                items: state.items,
                packedCount: state.packedCount,
                totalCount: state.totalCount,
                suggestions: state.suggestions,
                canEdit: canEdit,
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: canEdit && !AdaptivePlatform.isIOS
            ? FloatingActionButton.extended(
                onPressed: () => _showAddForm(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.baggageAddItemTitle),
              )
            : null,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required List<BaggageItem> items,
    required int packedCount,
    required int totalCount,
    required List suggestions,
    required bool canEdit,
    bool suggestionsLoading = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final unpackedItems = items.where((i) => !i.isPacked).toList();
    final packedItems = items.where((i) => i.isPacked).toList();

    return CustomScrollView(
      slivers: [
        // Progress header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              AppSpacing.space16,
              AppSpacing.space16,
              AppSpacing.space8,
            ),
            child: BaggageProgressHeader(
              packedCount: packedCount,
              totalCount: totalCount,
            ),
          ),
        ),

        // AI suggestions loading indicator
        if (suggestionsLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space16),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
          ),

        // AI suggestions section
        if (suggestions.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                AppSpacing.space16,
                AppSpacing.space16,
                AppSpacing.space8,
              ),
              child: Text(
                l10n.baggageSuggestionsTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final suggestion = suggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                  child: BaggageSuggestionCard(
                    suggestion: suggestion,
                    onAccept: () {
                      context.read<BaggageBloc>().add(
                        AcceptSuggestion(
                          tripId: tripId,
                          suggestion: suggestion,
                        ),
                      );
                    },
                    onDismiss: () {
                      context.read<BaggageBloc>().add(
                        DismissSuggestion(suggestion: suggestion),
                      );
                    },
                  ),
                );
              }, childCount: suggestions.length),
            ),
          ),
        ],

        // "To pack" section
        if (unpackedItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                AppSpacing.space16,
                AppSpacing.space16,
                AppSpacing.space8,
              ),
              child: Text(
                l10n.baggageToPack,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
            sliver: SliverReorderableList(
              itemCount: unpackedItems.length,
              onReorder: (oldIndex, newIndex) {
                context.read<BaggageBloc>().add(
                  ReorderBaggageItem(oldIndex: oldIndex, newIndex: newIndex),
                );
              },
              itemBuilder: (context, index) {
                final item = unpackedItems[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(item.id),
                  index: index,
                  child: AnimatedSize(
                    duration: AppAnimations.cardTransition,
                    curve: AppAnimations.standardCurve,
                    child: BaggageItemTile(
                      item: item,
                      isReadOnly: !canEdit,
                      onToggle: () {
                        context.read<BaggageBloc>().add(
                          TogglePacked(tripId: tripId, item: item),
                        );
                      },
                      onEdit: canEdit
                          ? () => _showEditForm(context, item)
                          : null,
                      onDelete: canEdit
                          ? () {
                              context.read<BaggageBloc>().add(
                                DeleteBaggageItem(
                                  tripId: tripId,
                                  itemId: item.id,
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // "Packed" section
        if (packedItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                AppSpacing.space16,
                AppSpacing.space16,
                AppSpacing.space8,
              ),
              child: Text(
                l10n.baggagePacked,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.hint,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = packedItems[index];
                return AnimatedSize(
                  duration: AppAnimations.cardTransition,
                  curve: AppAnimations.standardCurve,
                  child: BaggageItemTile(
                    item: item,
                    isReadOnly: !canEdit,
                    onToggle: () {
                      context.read<BaggageBloc>().add(
                        TogglePacked(tripId: tripId, item: item),
                      );
                    },
                    onEdit: canEdit ? () => _showEditForm(context, item) : null,
                    onDelete: canEdit
                        ? () {
                            context.read<BaggageBloc>().add(
                              DeleteBaggageItem(
                                tripId: tripId,
                                itemId: item.id,
                              ),
                            );
                          }
                        : null,
                  ),
                );
              }, childCount: packedItems.length),
            ),
          ),
        ],

        // Bottom padding for FAB
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _showAddForm(BuildContext context) {
    final bloc = context.read<BaggageBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: BaggageAddForm(tripId: tripId),
      ),
    );
  }

  void _showEditForm(BuildContext context, BaggageItem item) {
    final bloc = context.read<BaggageBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: BaggageEditForm(tripId: tripId, item: item),
      ),
    );
  }
}
