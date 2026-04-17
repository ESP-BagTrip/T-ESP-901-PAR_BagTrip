import 'package:bagtrip/activities/bloc/activity_bloc.dart';
import 'package:bagtrip/activities/widgets/activity_form.dart';
import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/subpage_state.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/design/widgets/review/activity_tile.dart';
import 'package:bagtrip/design/widgets/review/animated_count.dart';
import 'package:bagtrip/design/widgets/review/blank_canvas_hero.dart';
import 'package:bagtrip/design/widgets/review/density_aware_list_view.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/sheets/ai_suggestions_sheet.dart';
import 'package:bagtrip/design/widgets/review/state_responsive_hero.dart';
import 'package:bagtrip/design/widgets/review/tap_scale_aware.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// /activities subpage — state-responsive v3.
///
/// Renders one of six layouts via `resolveSubpageState` instead of a single
/// static scaffold:
/// - booting      → skeleton LoadingView
/// - blankCanvas  → full-screen BlankCanvasHero with pulse icon
/// - sparse/dense → StateResponsiveHero + DensityAwareListView
/// - viewer       → same list, no CTAs, no Dismissible
/// - archive      → muted list, "Give a review" tertiary CTA
/// - error        → hero error card with retry
class ActivitiesView extends StatefulWidget {
  final String tripId;
  final String role;
  final bool isCompleted;
  final DateTime? tripStartDate;

  const ActivitiesView({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
    this.tripStartDate,
  });

  @override
  State<ActivitiesView> createState() => _ActivitiesViewState();
}

class _ActivitiesViewState extends State<ActivitiesView>
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
  bool get _hasDates => widget.tripStartDate != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MultiBlocListener(
      listeners: [
        BlocListener<ActivityBloc, ActivityState>(
          listener: (context, state) {
            if (state is ActivityQuotaExceeded) {
              PremiumPaywall.show(context);
            } else if (state is ActivitySuggestionsLoaded) {
              _showSuggestionsSheet(context, state.suggestions);
            } else if (state is ActivitiesLoaded) {
              // Keep the shared TripDetailBloc in sync.
              context.read<TripDetailBloc>().add(RefreshTripDetail());
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: ColorName.surfaceVariant,
        body: BlocBuilder<ActivityBloc, ActivityState>(
          builder: (context, state) {
            final isLoading =
                state is ActivityLoading || state is ActivitySuggestionsLoading;
            final hasError = state is ActivityError;
            final activities = switch (state) {
              ActivitiesLoaded() => state.activities,
              ActivitySuggestionsLoaded() => state.activities,
              _ => const <Activity>[],
            };
            final screenState = resolveSubpageState(
              isLoading: isLoading,
              hasError: hasError,
              count: activities.length,
              canEdit: _canEdit,
              isCompleted: widget.isCompleted,
            );

            switch (screenState) {
              case SubpageScreenState.booting:
                return const LoadingView();
              case SubpageScreenState.error:
                return ErrorView(
                  message: toUserFriendlyMessage(
                    (state as ActivityError).error,
                    l10n,
                  ),
                  onRetry: () => context.read<ActivityBloc>().add(
                    LoadActivities(tripId: widget.tripId),
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
                  activities,
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
    if (!_hasDates) {
      return BlankCanvasHero(
        icon: Icons.calendar_month_outlined,
        title: l10n.blankActivitiesNoDatesTitle,
        subtitle: l10n.blankActivitiesNoDatesSubtitle,
        primaryLabel: l10n.blankActivitiesNoDatesPrimary,
        primaryLeadingIcon: Icons.arrow_back_rounded,
        onPrimary: () => Navigator.of(context).maybePop(),
        breathingIconBuilder: BlankCanvasBreathing.pulse(),
      );
    }
    return BlankCanvasHero(
      icon: Icons.event_outlined,
      title: l10n.blankActivitiesTitle,
      subtitle: l10n.blankActivitiesSubtitle,
      primaryLabel: l10n.blankActivitiesPrimary,
      primaryLeadingIcon: Icons.add_rounded,
      onPrimary: () {
        AppHaptics.medium();
        _showForm(context, widget.tripId);
      },
      secondaryLabel: l10n.blankActivitiesSecondary,
      secondaryLeadingIcon: Icons.auto_awesome_rounded,
      onSecondary: () {
        AppHaptics.light();
        context.read<ActivityBloc>().add(
          SuggestActivities(tripId: widget.tripId),
        );
      },
      breathingIconBuilder: BlankCanvasBreathing.pulse(),
    );
  }

  Widget _buildPopulated(
    BuildContext context,
    AppLocalizations l10n,
    ActivityState state,
    List<Activity> activities,
    SubpageScreenState screenState,
    HeroDensity density,
  ) {
    final hasMore = switch (state) {
      ActivitiesLoaded() => state.hasMore,
      ActivitySuggestionsLoaded() => state.hasMore,
      _ => false,
    };
    final isViewer = screenState == SubpageScreenState.viewer;
    final isArchive = screenState == SubpageScreenState.archive;
    final interactive = !isViewer && !isArchive;
    final uniqueDays = activities
        .map((a) => DateFormat('yyyy-MM-dd').format(a.date))
        .toSet()
        .length;

    final body = DensityAwareListView<Activity>(
      density: density,
      items: activities,
      itemBuilder: (context, activity, _) => _ActivityRow(
        activity: activity,
        canEdit: interactive,
        onEdit: () => _showForm(context, widget.tripId, activity: activity),
        onDelete: () => _confirmDelete(context, activity, l10n),
        onValidate: () => _showValidateModal(context, activity),
      ),
      leading:
          activities.any(
            (a) => a.validationStatus == ValidationStatus.suggested,
          )
          ? _SuggestedPill(l10n: l10n)
          : null,
    );

    return Column(
      children: [
        StateResponsiveHero(
          title: l10n.activitiesTitle,
          density: density,
          meta: AnimatedCount(
            value: activities.length,
            formatter: (n) =>
                l10n.activitiesHeroMeta(n, uniqueDays.clamp(1, 9999)),
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
                    tooltip: l10n.activitiesSuggestionsTitle,
                    onPressed: () {
                      AppHaptics.light();
                      context.read<ActivityBloc>().add(
                        SuggestActivities(tripId: widget.tripId),
                      );
                    },
                  ),
                ]
              : null,
        ),
        Expanded(
          child: ScrollReactiveCtaScaffold(
            controller: _footerController,
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<ActivityBloc>().add(
                  LoadActivities(tripId: widget.tripId),
                );
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification &&
                      n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
                      hasMore) {
                    context.read<ActivityBloc>().add(
                      LoadMoreActivities(tripId: widget.tripId),
                    );
                  }
                  return false;
                },
                child: body,
              ),
            ),
            footer: interactive
                ? PillCtaButton(
                    label: l10n.addActivity,
                    leadingIcon: Icons.add_rounded,
                    onTap: () {
                      AppHaptics.medium();
                      _showForm(context, widget.tripId);
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    Activity activity,
    AppLocalizations l10n,
  ) {
    showAdaptiveAlertDialog(
      context: context,
      title: l10n.activityDeleteTitle,
      content: l10n.activityDeleteConfirm,
      confirmLabel: l10n.deleteButton,
      cancelLabel: l10n.cancelButton,
      isDestructive: true,
      onConfirm: () {
        AppHaptics.medium();
        context.read<ActivityBloc>().add(
          DeleteActivity(tripId: widget.tripId, activityId: activity.id),
        );
      },
    );
  }

  void _showSuggestionsSheet(
    BuildContext context,
    List<Map<String, dynamic>> suggestions,
  ) {
    final bloc = context.read<ActivityBloc>();
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiSuggestionsSheet<Map<String, dynamic>>(
        title: l10n.activitiesSuggestionsTitle,
        subtitle: l10n.activitiesTitle,
        suggestions: suggestions,
        emptyTitle: l10n.emptyActivitiesTitle,
        emptySubtitle: l10n.activityDisclaimerSubtitle,
        disclaimer: l10n.activityDisclaimerSubtitle,
        itemBuilder: (sheetContext, s, _) => _SuggestionCard(
          suggestion: s,
          onAccept: () {
            final suggestedDay = s['suggestedDay'] as int?;
            final String activityDate;
            if (suggestedDay != null && widget.tripStartDate != null) {
              activityDate = widget.tripStartDate!
                  .add(Duration(days: suggestedDay - 1))
                  .toIso8601String()
                  .split('T')[0];
            } else {
              activityDate = DateTime.now().toIso8601String().split('T')[0];
            }
            bloc.add(
              AddSuggestedActivity(
                tripId: widget.tripId,
                data: {
                  'title': s['title'] ?? '',
                  'description': s['description'],
                  'category': s['category'] ?? 'OTHER',
                  'estimatedCost': s['estimatedCost'],
                  'location': s['location'],
                  'date': activityDate,
                  'validationStatus': 'SUGGESTED',
                },
              ),
            );
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }

  void _showForm(BuildContext context, String tripId, {Activity? activity}) {
    final bloc = context.read<ActivityBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _FormWrapper(
        child: ActivityForm(
          tripId: tripId,
          activity: activity,
          onSave: (data) {
            if (activity != null) {
              bloc.add(
                UpdateActivity(
                  tripId: tripId,
                  activityId: activity.id,
                  data: data,
                ),
              );
            } else {
              bloc.add(CreateActivity(tripId: tripId, data: data));
            }
            Navigator.of(sheetCtx).pop();
          },
        ),
      ),
    );
  }

  void _showValidateModal(BuildContext context, Activity activity) {
    final l10n = AppLocalizations.of(context)!;
    final costController = TextEditingController(
      text: activity.estimatedCost?.toStringAsFixed(2) ?? '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.cornerRadius24),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.space24,
            right: AppSpacing.space24,
            top: AppSpacing.space24,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom +
                AppSpacing.space24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.activityValidateConfirmTitle,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSerifDisplay,
                  fontSize: 20,
                  color: ColorName.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                l10n.activityValidateConfirmMessage,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 13,
                  color: ColorName.hint,
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              TextField(
                controller: costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.activityValidateCostLabel,
                  border: const OutlineInputBorder(),
                  prefixText: '\u20ac ',
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              PillCtaButton(
                label: l10n.activityValidateConfirm,
                onTap: () {
                  AppHaptics.medium();
                  final newCost = double.tryParse(costController.text);
                  final data = <String, dynamic>{
                    'validationStatus': 'VALIDATED',
                  };
                  if (newCost != null) {
                    data['estimatedCost'] = newCost;
                  }
                  context.read<ActivityBloc>().add(
                    UpdateActivity(
                      tripId: widget.tripId,
                      activityId: activity.id,
                      data: data,
                    ),
                  );
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestedPill extends StatelessWidget {
  const _SuggestedPill({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: ColorName.secondary.withValues(alpha: 0.08),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: ColorName.secondary,
          ),
          const SizedBox(width: AppSpacing.space8),
          Flexible(
            child: Text(
              l10n.activityDisclaimerSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorName.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.activity,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    required this.onValidate,
  });

  final Activity activity;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final tile = ActivityTile(
      title: activity.title,
      description: activity.description ?? '',
      category: activity.category.name,
    );
    if (!canEdit) return tile;
    final tappable = TapScaleAware(
      onTap: () {
        AppHaptics.light();
        if (activity.validationStatus == ValidationStatus.suggested) {
          onValidate();
        } else {
          onEdit();
        }
      },
      child: tile,
    );
    return Dismissible(
      key: ValueKey('activity-${activity.id}'),
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
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: tappable,
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onAccept});

  final Map<String, dynamic> suggestion;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    final suggestedDay = s['suggestedDay'] as int?;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s['title'] as String? ?? '',
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 16,
                    color: ColorName.primaryDark,
                  ),
                ),
              ),
              if (suggestedDay != null) ...[
                const SizedBox(width: AppSpacing.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ColorName.secondary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    'D$suggestedDay',
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ColorName.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (s['description'] != null) ...[
            const SizedBox(height: AppSpacing.space8),
            Text(
              s['description'] as String,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 13,
                color: ColorName.hint,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space12),
          Align(
            alignment: Alignment.centerRight,
            child: PillCtaButton(
              label: AppLocalizations.of(context)!.addActivity,
              leadingIcon: Icons.add_rounded,
              onTap: onAccept,
            ),
          ),
        ],
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
