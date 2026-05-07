import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/adaptive/adaptive_edit_dialog.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/panel_chips_bar.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/review_hero.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/plan_trip/helpers/destination_cover.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/view/panels/budget_panel.dart';
import 'package:bagtrip/trip_detail/view/panels/essentials_panel.dart';
import 'package:bagtrip/trip_detail/view/panels/flights_panel.dart';
import 'package:bagtrip/trip_detail/view/panels/hotel_panel.dart';
import 'package:bagtrip/trip_detail/view/panels/itinerary_panel.dart';
import 'package:bagtrip/trip_detail/view/panels/validation_board_panel.dart';
import 'package:bagtrip/trip_detail/view/panels/shares_panel.dart';
import 'package:bagtrip/trip_detail/widgets/completion_ring.dart';
import 'package:bagtrip/trip_detail/widgets/date_range_picker_sheet.dart';
import 'package:bagtrip/trip_detail/widgets/hero_overflow_menu.dart';
import 'package:bagtrip/trip_detail/widgets/review_shimmer.dart';
import 'package:bagtrip/trip_detail/widgets/travelers_edit_sheet.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart'
    show LoadTripsByStatus, TripManagementBloc;
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// New "wizard mirror" edit view: dark hero + pill chips bar + TabBarView
/// with 7 domain panels. Replaces the legacy SliverAppBar + stacked-sections
/// layout.
class TripDetailView extends StatelessWidget {
  final String tripId;

  const TripDetailView({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.surfaceVariant,
      body: BlocConsumer<TripDetailBloc, TripDetailState>(
        listener: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          if (state is TripDetailDeleted) {
            context.read<HomeBloc>().add(RefreshHome());
            for (final s in ['ongoing', 'planned', 'completed']) {
              context.read<TripManagementBloc>().add(
                LoadTripsByStatus(status: s),
              );
            }
            const HomeRoute().go(context);
          }
          if (state is TripDetailError) {
            AppSnackBar.showError(
              context,
              message: toUserFriendlyMessage(state.error, l10n),
            );
          }
          if (state is TripDetailLoaded && state.validationError != null) {
            AppSnackBar.showError(context, message: l10n.cannotFinalizeMessage);
          }
          if (state is TripDetailLoaded && state.operationError != null) {
            AppSnackBar.showError(
              context,
              message: toUserFriendlyMessage(state.operationError!, l10n),
            );
          }
        },
        builder: (context, state) {
          if (state is TripDetailLoading) {
            return const ReviewShimmer();
          }
          if (state is TripDetailError) {
            return ErrorView(
              message: toUserFriendlyMessage(
                state.error,
                AppLocalizations.of(context)!,
              ),
              onRetry: () => context.read<TripDetailBloc>().add(
                LoadTripDetail(tripId: tripId),
              ),
            );
          }
          if (state is TripDetailLoaded) {
            return _LoadedTripView(tripId: tripId, state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LoadedTripView extends StatefulWidget {
  const _LoadedTripView({required this.tripId, required this.state});

  final String tripId;
  final TripDetailLoaded state;

  @override
  State<_LoadedTripView> createState() => _LoadedTripViewState();
}

class _LoadedTripViewState extends State<_LoadedTripView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late final PanelFooterCtaController _footerController;

  TripDetailLoaded get state => widget.state;
  bool get _canEdit => state.canEdit;
  bool get _hasSharesTab => state.isOwner;
  int get _tabCount => _hasSharesTab ? 7 : 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _tabController.addListener(_onTabChanged);
    _footerController = PanelFooterCtaController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant _LoadedTripView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newCount = _tabCount;
    if (_tabController.length != newCount) {
      final old = _tabController;
      old.removeListener(_onTabChanged);
      _tabController = TabController(
        length: newCount,
        vsync: this,
        initialIndex: old.index.clamp(0, newCount - 1),
      );
      _tabController.addListener(_onTabChanged);
      old.dispose();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _footerController.show();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trip = state.trip;
    final labels = _tabLabels(l10n);

    return Column(
      children: [
        ReviewHero(
          city: _heroCity(trip, l10n),
          daysLabel: _heroDaysLabel(l10n),
          dateRangeLabel: _heroDateRangeLabel(context, trip),
          budgetLabel: _heroBudgetLabel(),
          coverImageUrl: _resolveCoverImage(trip),
          onEditDates: _canEdit ? () => _showDateRangePicker(context) : null,
          onBack: () => const HomeRoute().go(context),
          onOverflow: () => _handleOverflow(context),
          trailing: CompletionRing(
            percentage: state.completionResult.percentage,
            onTap: _canEdit
                ? () => _showCompletionSegmentsSheet(context)
                : null,
          ),
          statusBadge: _buildStatusBadge(l10n),
        ),
        ColoredBox(
          color: ColorName.primaryDark,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space8),
            child: PanelChipsBar(
              labels: labels,
              controller: _tabController,
              incompleteFlags: _incompleteFlags(),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<TripDetailBloc>().add(RefreshTripDetail());
                  },
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _footerController.handleScrollNotification,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ValidationBoardPanel(
                          state: state,
                          onJumpToTab: _tabController.animateTo,
                        ),
                        FlightsPanel(
                          tripId: widget.tripId,
                          flights: state.flights,
                          canEdit: _canEdit,
                          isCompleted: state.isCompleted,
                          role: state.trip.role ?? 'OWNER',
                          tracking: state.trip.flightsTracking,
                        ),
                        HotelPanel(
                          tripId: widget.tripId,
                          trip: state.trip,
                          accommodations: state.accommodations,
                          canEdit: _canEdit,
                          isCompleted: state.isCompleted,
                          role: state.trip.role ?? 'OWNER',
                        ),
                        ItineraryPanel(
                          tripId: widget.tripId,
                          tripStartDate: state.trip.startDate,
                          // SMP-324 — undated FOOD / TRANSPORT
                          // recommendations live outside the day-by-day
                          // grid; the timeline panel only consumes
                          // dated rows. The undated items surface in
                          // their own sections (review screen + future
                          // dedicated tabs).
                          activities: state.activities
                              .where((a) => a.date != null)
                              .toList(),
                          totalDays: state.totalDays,
                          selectedDayIndex: state.selectedDayIndex,
                          canEdit: _canEdit,
                          isCompleted: state.isCompleted,
                          role: state.trip.role ?? 'OWNER',
                        ),
                        EssentialsPanel(
                          tripId: widget.tripId,
                          items: state.baggageItems,
                          canEdit: _canEdit,
                          isCompleted: state.isCompleted,
                          role: state.trip.role ?? 'OWNER',
                        ),
                        BudgetPanel(
                          tripId: widget.tripId,
                          budgetSummary: state.budgetSummary,
                          budgetItems: state.budgetItems,
                          totalDays: state.totalDays,
                          canEdit: _canEdit,
                          isCompleted: state.isCompleted,
                          role: state.trip.role ?? 'OWNER',
                        ),
                        if (_hasSharesTab)
                          SharesPanel(
                            tripId: widget.tripId,
                            shares: state.shares,
                            role: state.trip.role ?? 'OWNER',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(context, l10n),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero helpers ────────────────────────────────────────────────────────

  String _heroCity(Trip trip, AppLocalizations l10n) {
    if (trip.destinationName != null && trip.destinationName!.isNotEmpty) {
      return trip.destinationName!;
    }
    if (trip.title != null && trip.title!.isNotEmpty) return trip.title!;
    return l10n.myTripFallback;
  }

  String _heroDaysLabel(AppLocalizations l10n) {
    if (state.totalDays <= 0) return '';
    return l10n.summaryDaysCount(state.totalDays).toUpperCase();
  }

  String _heroDateRangeLabel(BuildContext context, Trip trip) {
    if (trip.startDate == null || trip.endDate == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    final fmt = DateFormat('d MMM yyyy', locale);
    return '${fmt.format(trip.startDate!)} – ${fmt.format(trip.endDate!)}';
  }

  String _heroBudgetLabel() {
    final totalBudget = state.budgetSummary?.totalBudget;
    if (totalBudget == null || totalBudget <= 0) return '';
    return totalBudget.formatPrice();
  }

  /// Cover image for the hero: prefer the URL stored on the trip (populated by
  /// the backend at accept time from Unsplash), fall back to the shared
  /// destination-cover helper so manual trips also get an image.
  String? _resolveCoverImage(Trip trip) {
    final fromBackend = trip.coverImageUrl;
    if (fromBackend != null && fromBackend.isNotEmpty) return fromBackend;
    final city = trip.destinationName ?? trip.title ?? '';
    if (city.isEmpty) return null;
    return destinationCoverUrl(city: city, country: '');
  }

  Widget? _buildStatusBadge(AppLocalizations l10n) {
    if (state.isViewer) {
      return _StatusPill(
        label: l10n.viewerBadgeReadOnly,
        color: ColorName.hint,
      );
    }
    if (state.isCompleted) {
      return _StatusPill(label: l10n.tripComplete, color: ColorName.secondary);
    }
    return null;
  }

  // ── Tab wiring ──────────────────────────────────────────────────────────

  List<String> _tabLabels(AppLocalizations l10n) => [
    l10n.reviewTabOverview,
    l10n.reviewTabFlights,
    l10n.reviewTabHotel,
    l10n.reviewTabItinerary,
    l10n.reviewTabEssentials,
    l10n.reviewTabBudget,
    if (_hasSharesTab) l10n.sharingSectionTitle,
  ];

  List<bool> _incompleteFlags() {
    final result = state.completionResult;
    bool incomplete(CompletionSegmentType t) => !result.segment(t).isComplete;
    return [
      // Overview — derived from all other domains
      false,
      incomplete(CompletionSegmentType.flights),
      incomplete(CompletionSegmentType.accommodation),
      incomplete(CompletionSegmentType.activities),
      incomplete(CompletionSegmentType.baggage),
      // Budget chip is read-only (real vs forecast) — no badge.
      false,
      if (_hasSharesTab) false,
    ];
  }

  // ── Footer CTA per tab ──────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    if (state.isCompleted) {
      return PanelFooterCta(
        controller: _footerController,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              AppSpacing.space8,
              AppSpacing.space16,
              AppSpacing.space16,
            ),
            child: PillCtaButton(
              label: l10n.tripGiveReview,
              variant: PillVariant.outlined,
              onTap: () => FeedbackRoute(tripId: widget.tripId).go(context),
            ),
          ),
        ),
      );
    }
    // Per-tab footer CTA is obsolete: each panel owns its own FAB and the
    // preview sheets surface edit / delete. Trip-level footer remains for
    // the completed ("give review") case only.
    return const SizedBox.shrink();
  }

  // ── Overflow menu + editors ─────────────────────────────────────────────

  Future<void> _handleOverflow(BuildContext context) async {
    final result = await showHeroOverflowMenu(
      context: context,
      trip: state.trip,
      canEdit: _canEdit,
      isOwner: state.isOwner,
    );
    if (!context.mounted || result == null) return;
    switch (result) {
      case HeroOverflowAction.editTitle:
        await _showTitleEditor(context);
      case HeroOverflowAction.editTravelers:
        await _showTravelersEditor(context);
      case HeroOverflowAction.share:
        if (_hasSharesTab) {
          AppHaptics.light();
          _tabController.animateTo(6);
        }
      case HeroOverflowAction.markAsReady:
        _markAsReady(context);
      case HeroOverflowAction.markAsCompleted:
        AppHaptics.medium();
        context.read<TripDetailBloc>().add(
          UpdateTripStatus(status: 'COMPLETED'),
        );
      case HeroOverflowAction.giveReview:
        FeedbackRoute(tripId: widget.tripId).go(context);
      case HeroOverflowAction.deleteTrip:
        _confirmDelete(context);
    }
  }

  Future<void> _showTitleEditor(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final newTitle = await showAdaptiveEditDialog(
      context: context,
      title: l10n.editTripTitle,
      currentValue: state.trip.title ?? '',
      confirmLabel: l10n.saveButton,
      cancelLabel: l10n.cancelButton,
    );
    if (newTitle != null && newTitle.isNotEmpty && context.mounted) {
      context.read<TripDetailBloc>().add(UpdateTripTitle(title: newTitle));
    }
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<TripDetailBloc>();
    final result = await showTripDateRangePicker(
      context: context,
      currentStart: state.trip.startDate,
      currentEnd: state.trip.endDate,
    );
    if (result == null || !context.mounted) return;

    final newStart = result.start;
    final newEnd = result.end;

    final outOfRange = state.activities.where((a) {
      // Undated AI recommendations (FOOD / TRANSPORT) never fall out of
      // range — they live on the side, not on the calendar.
      if (a.date == null) return false;
      final activityDate = a.date!;
      final d = DateTime(
        activityDate.year,
        activityDate.month,
        activityDate.day,
      );
      final s = DateTime(newStart.year, newStart.month, newStart.day);
      final e = DateTime(newEnd.year, newEnd.month, newEnd.day);
      return d.isBefore(s) || d.isAfter(e);
    }).toList();

    if (outOfRange.isNotEmpty && context.mounted) {
      showAdaptiveAlertDialog(
        context: context,
        title: l10n.activitiesOutOfRangeTitle,
        content: l10n.activitiesOutOfRangeMessage(outOfRange.length),
        confirmLabel: l10n.continueButton,
        cancelLabel: l10n.cancelButton,
        isDestructive: true,
        onConfirm: () {
          bloc.add(UpdateTripDates(startDate: newStart, endDate: newEnd));
        },
      );
      return;
    }
    bloc.add(UpdateTripDates(startDate: newStart, endDate: newEnd));
  }

  Future<void> _showTravelersEditor(BuildContext context) async {
    final newCount = await showTravelersEditSheet(
      context: context,
      currentValue: state.trip.nbTravelers ?? 1,
    );
    if (newCount != null && context.mounted) {
      context.read<TripDetailBloc>().add(
        UpdateTripTravelers(nbTravelers: newCount),
      );
    }
  }

  void _markAsReady(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trip = state.trip;
    final hasDestination =
        trip.destinationName != null && trip.destinationName!.isNotEmpty;
    final hasDates = trip.startDate != null && trip.endDate != null;
    if (!hasDestination || !hasDates) {
      final missing = <String>[];
      if (!hasDestination) missing.add(l10n.finalizeMissingDestination);
      if (!hasDates) missing.add(l10n.finalizeMissingDates);
      showAdaptiveAlertDialog(
        context: context,
        title: l10n.cannotFinalizeTitle,
        content: missing.join('\n'),
        confirmLabel: 'OK',
        cancelLabel: l10n.cancelButton,
      );
      return;
    }
    AppHaptics.medium();
    context.read<TripDetailBloc>().add(UpdateTripStatus(status: 'PLANNED'));
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showAdaptiveAlertDialog(
      context: context,
      title: l10n.tripDeleteTitle,
      content: l10n.tripDeleteConfirm,
      confirmLabel: l10n.deleteButton,
      cancelLabel: l10n.cancelButton,
      isDestructive: true,
      onConfirm: () {
        context.read<TripDetailBloc>().add(DeleteTripDetail());
      },
    );
  }

  Future<void> _showCompletionSegmentsSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final segments = state.completionResult.segments;
    final incomplete = <CompletionSegmentType>[
      for (final entry in segments.entries)
        if (!entry.value.isComplete) entry.key,
    ];
    if (incomplete.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
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
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Text(
                  l10n.completionSegmentsSheetTitle,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ColorName.primaryDark,
                  ),
                ),
              ),
              ...incomplete.map(
                (type) => ListTile(
                  leading: Icon(_iconForSegment(type)),
                  title: Text(_labelForSegment(type, l10n)),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    final tabIndex = _tabIndexForSegment(type);
                    if (tabIndex != null) {
                      _tabController.animateTo(tabIndex);
                    }
                  },
                ),
              ),
              // B20 — make it explicit that budget is tracked separately
              // and not included in the completion percentage so users
              // don't read "100% complete" as "budget on track".
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space12,
                  AppSpacing.space16,
                  AppSpacing.space16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.reviewInk.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      child: Text(
                        l10n.completionScoreBudgetNote,
                        style: TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.reviewInk.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconForSegment(CompletionSegmentType type) {
    return switch (type) {
      CompletionSegmentType.flights => Icons.flight_takeoff_rounded,
      CompletionSegmentType.accommodation => Icons.hotel_rounded,
      CompletionSegmentType.activities => Icons.hiking_rounded,
      CompletionSegmentType.baggage => Icons.luggage_rounded,
    };
  }

  String _labelForSegment(CompletionSegmentType type, AppLocalizations l10n) {
    return switch (type) {
      CompletionSegmentType.flights => l10n.reviewTabFlights,
      CompletionSegmentType.accommodation => l10n.reviewTabHotel,
      CompletionSegmentType.activities => l10n.reviewTabItinerary,
      CompletionSegmentType.baggage => l10n.reviewTabEssentials,
    };
  }

  int? _tabIndexForSegment(CompletionSegmentType type) {
    return switch (type) {
      CompletionSegmentType.flights => 1,
      CompletionSegmentType.accommodation => 2,
      CompletionSegmentType.activities => 3,
      CompletionSegmentType.baggage => 4,
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: color,
        ),
      ),
    );
  }
}
