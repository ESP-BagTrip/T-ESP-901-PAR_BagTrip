import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/baggage/widgets/baggage_add_form.dart';
import 'package:bagtrip/baggage/widgets/baggage_celebration.dart';
import 'package:bagtrip/baggage/widgets/baggage_edit_form.dart';
import 'package:bagtrip/baggage/widgets/baggage_suggestion_card.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/subpage_state.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/design/widgets/review/animated_count.dart';
import 'package:bagtrip/design/widgets/review/blank_canvas_hero.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/design/widgets/review/pack_item.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/progress_strip.dart';
import 'package:bagtrip/design/widgets/review/state_responsive_hero.dart';
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
        body: BlocBuilder<BaggageBloc, BaggageState>(
          builder: (context, state) {
            final isLoading =
                state is BaggageLoading || state is BaggageSuggestionsLoading;
            final hasError = state is BaggageError;
            final items = switch (state) {
              BaggageLoaded() => state.items,
              BaggageSuggestionsLoading() => state.items,
              _ => const <BaggageItem>[],
            };
            final screenState = resolveSubpageState(
              isLoading: isLoading,
              hasError: hasError,
              count: items.length,
              canEdit: _canEdit,
              isCompleted: widget.isCompleted,
            );
            switch (screenState) {
              case SubpageScreenState.booting:
                return const LoadingView();
              case SubpageScreenState.error:
                return ErrorView(
                  message: toUserFriendlyMessage(
                    (state as BaggageError).error,
                    l10n,
                  ),
                  onRetry: () => context.read<BaggageBloc>().add(
                    LoadBaggage(tripId: widget.tripId),
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
                  state,
                  items,
                  screenState,
                  density,
                );
            }
          },
        ),
      ),
    );
  }

  Widget _buildBlankCanvas(BuildContext context, AppLocalizations l10n) {
    return BlankCanvasHero(
      icon: Icons.luggage_outlined,
      title: l10n.blankBaggageTitle,
      subtitle: l10n.blankBaggageSubtitle,
      primaryLabel: l10n.blankBaggagePrimary,
      primaryLeadingIcon: Icons.add_rounded,
      onPrimary: () {
        AppHaptics.medium();
        _showAddForm(context);
      },
      secondaryLabel: l10n.blankBaggageSecondary,
      secondaryLeadingIcon: Icons.auto_awesome_rounded,
      onSecondary: () {
        AppHaptics.light();
        context.read<BaggageBloc>().add(SuggestBaggage(tripId: widget.tripId));
      },
      breathingIconBuilder: BlankCanvasBreathing.tilt(maxDegrees: 3),
    );
  }

  Widget _buildPopulated(
    BuildContext context,
    AppLocalizations l10n,
    BaggageState state,
    List<BaggageItem> items,
    SubpageScreenState screenState,
    HeroDensity density,
  ) {
    final isViewer = screenState == SubpageScreenState.viewer;
    final isArchive = screenState == SubpageScreenState.archive;
    final interactive = !isViewer && !isArchive;
    final packedCount = items.where((i) => i.isPacked).length;
    final totalCount = items.length;
    final unpacked = items.where((i) => !i.isPacked).toList();
    final packed = items.where((i) => i.isPacked).toList();
    final suggestions = state is BaggageLoaded ? state.suggestions : const [];
    final suggestionsLoading = state is BaggageSuggestionsLoading;

    return Column(
      children: [
        StateResponsiveHero(
          title: l10n.baggageTitle,
          density: density,
          meta: AnimatedCount(
            value: packedCount,
            formatter: (n) => l10n.baggageHeroMeta(n, totalCount),
          ),
          badge: isViewer
              ? HeroBadge(label: l10n.subpageHeroBadgeViewer)
              : isArchive
              ? HeroBadge(
                  label: l10n.subpageHeroBadgeCompleted,
                  tone: HeroBadgeTone.success,
                )
              : null,
          trailing: interactive
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
          child: ScrollReactiveCtaScaffold(
            controller: _footerController,
            body: ListView(
              padding: EdgeInsets.only(
                left: density == HeroDensity.sparse ? 24 : 12,
                right: density == HeroDensity.sparse ? 24 : 12,
                top: density == HeroDensity.sparse ? 24 : 12,
                bottom:
                    (density == HeroDensity.sparse ? 24 : 12) +
                    (interactive ? 96 : 24),
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
                          AppHaptics.medium();
                          context.read<BaggageBloc>().add(
                            AcceptSuggestion(
                              tripId: widget.tripId,
                              suggestion: s,
                            ),
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
                    canEdit: interactive,
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
                    canEdit: interactive,
                    tripId: widget.tripId,
                    onEditItem: (item) => _showEditForm(context, item),
                  ),
                ],
              ],
            ),
            footer: interactive
                ? PillCtaButton(
                    label: l10n.baggageAddItemTitle,
                    leadingIcon: Icons.add_rounded,
                    onTap: () {
                      AppHaptics.medium();
                      _showAddForm(context);
                    },
                  )
                : null,
          ),
        ),
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
