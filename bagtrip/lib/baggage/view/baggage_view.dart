import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/baggage/widgets/baggage_add_form.dart';
import 'package:bagtrip/baggage/widgets/baggage_celebration.dart';
import 'package:bagtrip/baggage/widgets/baggage_edit_form.dart';
import 'package:bagtrip/baggage/widgets/baggage_suggestion_card.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/design/widgets/review/pack_item.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/progress_strip.dart';
import 'package:bagtrip/design/widgets/review/sub_page_hero.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BaggageView extends StatefulWidget {
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
  State<BaggageView> createState() => _BaggageViewState();
}

class _BaggageViewState extends State<BaggageView>
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

  bool get _canEdit => widget.role != 'VIEWER' && !widget.isCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            showDialog<void>(
              context: context,
              barrierColor: Colors.black54,
              builder: (_) => const BaggageCelebration(),
            );
          },
        ),
        BlocListener<BaggageBloc, BaggageState>(
          listenWhen: (_, current) => current is BaggageLoaded,
          listener: (context, _) =>
              context.read<TripDetailBloc>().add(RefreshTripDetail()),
        ),
      ],
      child: Scaffold(
        backgroundColor: ColorName.surfaceVariant,
        body: Column(
          children: [
            SubPageHero(
              title: l10n.baggageTitle,
              trailing: _canEdit
                  ? [
                      HeroNavButton(
                        icon: Icons.auto_awesome_rounded,
                        tooltip: l10n.baggageSuggestionsTooltip,
                        onPressed: () {
                          AppHaptics.light();
                          context.read<BaggageBloc>().add(
                            SuggestBaggage(tripId: widget.tripId),
                          );
                        },
                      ),
                    ]
                  : null,
            ),
            Expanded(
              child: BlocBuilder<BaggageBloc, BaggageState>(
                builder: (context, state) {
                  if (state is BaggageLoading) return const LoadingView();
                  if (state is BaggageError) {
                    return ErrorView(
                      message: toUserFriendlyMessage(state.error, l10n),
                      onRetry: () => context.read<BaggageBloc>().add(
                        LoadBaggage(tripId: widget.tripId),
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
                      suggestionsLoading: true,
                    );
                  }
                  if (state is BaggageLoaded) {
                    if (state.items.isEmpty && state.suggestions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.space24),
                        child: ElegantEmptyState(
                          icon: Icons.luggage_outlined,
                          title: l10n.emptyBaggageTitle,
                          subtitle: _canEdit ? l10n.emptyBaggageSubtitle : null,
                        ),
                      );
                    }
                    return _buildContent(
                      context,
                      items: state.items,
                      packedCount: state.packedCount,
                      totalCount: state.totalCount,
                      suggestions: state.suggestions,
                    );
                  }
                  return const SizedBox.shrink();
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
                      label: l10n.baggageAddItemTitle,
                      leadingIcon: Icons.add_rounded,
                      onTap: () => _showAddForm(context),
                    ),
                  ),
                ),
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
    required List<dynamic> suggestions,
    bool suggestionsLoading = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final unpacked = items.where((i) => !i.isPacked).toList();
    final packed = items.where((i) => i.isPacked).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space32 + 72,
      ),
      children: [
        ProgressStrip(
          label: l10n
              .baggageProgressLabel(packedCount, totalCount)
              .toUpperCase(),
          progress: totalCount == 0 ? 0 : packedCount / totalCount,
        ),
        const SizedBox(height: AppSpacing.space16),
        if (suggestionsLoading) ...[
          const Center(child: CircularProgressIndicator.adaptive()),
          const SizedBox(height: AppSpacing.space16),
        ],
        if (suggestions.isNotEmpty) ...[
          _SectionLabel(text: l10n.baggageSuggestionsTitle),
          const SizedBox(height: AppSpacing.space12),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space8),
              child: BaggageSuggestionCard(
                suggestion: s,
                onAccept: () {
                  context.read<BaggageBloc>().add(
                    AcceptSuggestion(tripId: widget.tripId, suggestion: s),
                  );
                },
                onDismiss: () {
                  context.read<BaggageBloc>().add(
                    DismissSuggestion(suggestion: s),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
        ],
        if (unpacked.isNotEmpty) ...[
          _SectionLabel(text: l10n.baggageToPack),
          const SizedBox(height: AppSpacing.space8),
          _PackGroup(
            items: unpacked,
            canEdit: _canEdit,
            tripId: widget.tripId,
            onEditItem: (item) => _showEditForm(context, item),
          ),
          const SizedBox(height: AppSpacing.space16),
        ],
        if (packed.isNotEmpty) ...[
          _SectionLabel(text: l10n.baggagePacked),
          const SizedBox(height: AppSpacing.space8),
          _PackGroup(
            items: packed,
            canEdit: _canEdit,
            tripId: widget.tripId,
            onEditItem: (item) => _showEditForm(context, item),
          ),
        ],
      ],
    );
  }

  void _showAddForm(BuildContext context) {
    final bloc = context.read<BaggageBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _FormWrapper(child: BaggageAddForm(tripId: widget.tripId)),
      ),
    );
  }

  void _showEditForm(BuildContext context, BaggageItem item) {
    final bloc = context.read<BaggageBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _FormWrapper(
          child: BaggageEditForm(tripId: widget.tripId, item: item),
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

class _PackGroup extends StatelessWidget {
  const _PackGroup({
    required this.items,
    required this.canEdit,
    required this.tripId,
    required this.onEditItem,
  });

  final List<BaggageItem> items;
  final bool canEdit;
  final String tripId;
  final ValueChanged<BaggageItem> onEditItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        primary: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: ColorName.primarySoftLight),
        itemBuilder: (context, idx) {
          final item = items[idx];
          return PackItem(
            item: item.name,
            reason: item.notes ?? '',
            checked: item.isPacked,
            onTap: () {
              AppHaptics.light();
              context.read<BaggageBloc>().add(
                TogglePacked(tripId: tripId, item: item),
              );
            },
            onEdit: canEdit ? () => onEditItem(item) : null,
            onDelete: canEdit
                ? () {
                    AppHaptics.medium();
                    context.read<BaggageBloc>().add(
                      DeleteBaggageItem(tripId: tripId, itemId: item.id),
                    );
                  }
                : null,
          );
        },
      ),
    );
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
