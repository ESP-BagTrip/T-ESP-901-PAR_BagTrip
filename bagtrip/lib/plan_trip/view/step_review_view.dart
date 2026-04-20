import 'dart:math' as math;

import 'package:bagtrip/core/extensions/datetime_ext.dart';
import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/activity_tile.dart';
import 'package:bagtrip/design/widgets/review/boarding_pass_card.dart';
import 'package:bagtrip/design/widgets/review/budget_stripe.dart';
import 'package:bagtrip/design/widgets/review/hotel_stats_grid.dart';
import 'package:bagtrip/design/widgets/review/pack_item.dart';
import 'package:bagtrip/design/widgets/review/panel_chips_bar.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/review_hero.dart';
import 'package:bagtrip/design/widgets/review/timeline_card.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/helpers/budget_breakdown.dart';
import 'package:bagtrip/plan_trip/models/trip_plan.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class StepReviewView extends StatefulWidget {
  const StepReviewView({super.key});

  @override
  State<StepReviewView> createState() => _StepReviewViewState();
}

class _StepReviewViewState extends State<StepReviewView>
    with TickerProviderStateMixin {
  final Set<int> _checkedEssentials = {};
  late final TabController _tabController;
  late final PanelFooterCtaController _footerController;
  int _selectedJourneyDay = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onReviewTabChanged);
    _footerController = PanelFooterCtaController(vsync: this);
  }

  void _onReviewTabChanged() {
    if (_tabController.indexIsChanging) return;
    _footerController.show();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onReviewTabChanged);
    _footerController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<PlanTripBloc, PlanTripState>(
      listenWhen: (prev, curr) => prev.error != curr.error,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(toUserFriendlyMessage(state.error!, l10n))),
          );
        }
      },
      builder: (context, state) {
        final plan = state.generatedPlan;
        if (plan == null) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final panels = [
          l10n.reviewTabOverview,
          l10n.reviewTabFlights,
          l10n.reviewTabHotel,
          l10n.reviewTabItinerary,
          l10n.reviewTabEssentials,
          l10n.reviewTabBudget,
        ];
        final dates = state.representativeDates;

        return Column(
          children: [
            ReviewHero(
              city: plan.destinationCity,
              daysLabel: l10n.summaryDaysCount(plan.durationDays),
              dateRangeLabel: _formatDateRange(context, dates),
              budgetLabel: l10n.summaryBudgetAmount('${plan.budgetEur}€'),
              onEditDates: () => _showDateEditor(context, state),
              onBack: () => context.read<PlanTripBloc>().add(
                const PlanTripEvent.backToProposals(),
              ),
              onClose: () => const HomeRoute().go(context),
            ),
            ColoredBox(
              color: ColorName.primaryDark,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                child: PanelChipsBar(
                  labels: panels,
                  controller: _tabController,
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: ColorName.surfaceVariant,
                      child: NotificationListener<ScrollNotification>(
                        onNotification:
                            _footerController.handleScrollNotification,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _OverviewPanel(plan: plan, dates: dates),
                            _FlightsPanel(plan: plan, dates: dates),
                            _HotelPanel(plan: plan, dates: dates),
                            _ItineraryPanel(
                              dayProgram: plan.dayProgram,
                              dayDescriptions: plan.dayDescriptions,
                              dayCategories: plan.dayCategories,
                              durationDays: plan.durationDays,
                              selectedDay: _selectedJourneyDay,
                              onSelectDay: (value) =>
                                  setState(() => _selectedJourneyDay = value),
                            ),
                            _EssentialsPanel(
                              items: plan.essentialItems,
                              reasons: plan.essentialReasons,
                              checked: _checkedEssentials,
                              onToggle: (index) {
                                AppHaptics.light();
                                setState(() {
                                  if (_checkedEssentials.contains(index)) {
                                    _checkedEssentials.remove(index);
                                  } else {
                                    _checkedEssentials.add(index);
                                  }
                                });
                              },
                            ),
                            _BudgetPanel(
                              total: plan.budgetEur.toDouble(),
                              budgetBreakdown: plan.budgetBreakdown,
                              durationDays: plan.durationDays,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PanelFooterCta(
                    controller: _footerController,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: PillCtaButton(
                          label: l10n.reviewCreateTrip,
                          isLoading: state.isCreating,
                          onTap: state.isCreating
                              ? null
                              : () {
                                  AppHaptics.medium();
                                  context.read<PlanTripBloc>().add(
                                    const PlanTripEvent.createTrip(),
                                  );
                                },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateRange(BuildContext context, (DateTime, DateTime) dates) {
    final locale = Localizations.localeOf(context).languageCode;
    final fmt = DateFormat('d MMM yyyy', locale);
    return '${fmt.format(dates.$1)} – ${fmt.format(dates.$2)}';
  }

  Future<void> _showDateEditor(
    BuildContext context,
    PlanTripState state,
  ) async {
    final (start, end) = state.representativeDates;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      initialDateRange: DateTimeRange(start: start, end: end),
    );
    if (range != null && context.mounted) {
      context.read<PlanTripBloc>().add(
        PlanTripEvent.updateReviewDates(range.start, range.end),
      );
    }
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.plan, required this.dates});

  final TripPlan plan;
  final (DateTime, DateTime) dates;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final events = <TimelineEvent>[
      if (plan.flightRoute.isNotEmpty)
        TimelineEvent(
          dayOffset: 0,
          type: TimelineEventType.flight,
          title: plan.flightRoute,
          subtitle: plan.flightDetails,
          badge: l10n.reviewTimelineFlight,
        ),
      if (plan.accommodationName.isNotEmpty)
        TimelineEvent(
          dayOffset: 0,
          type: TimelineEventType.hotel,
          title: plan.accommodationName,
          subtitle: l10n.reviewTimelineCheckIn,
          badge: l10n.reviewTabHotel,
        ),
      ..._buildActivityEvents(plan, l10n),
    ]..sort((a, b) => a.dayOffset.compareTo(b.dayOffset));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space8,
        AppSpacing.space16,
        AppSpacing.space16,
      ),
      itemCount: events.length + 1,
      itemBuilder: (context, index) {
        if (index == events.length) {
          return TimelineCard(
            event: TimelineEvent(
              dayOffset: math.max(plan.durationDays - 1, 0),
              type: TimelineEventType.hotel,
              title: l10n.reviewTimelineCheckOut,
              subtitle: DateFormat('d MMM').format(dates.$2),
              badge: l10n.reviewTabHotel,
            ),
            firstDate: dates.$1,
          );
        }
        return TimelineCard(event: events[index], firstDate: dates.$1);
      },
    );
  }

  List<TimelineEvent> _buildActivityEvents(
    TripPlan plan,
    AppLocalizations l10n,
  ) {
    if (plan.dayProgram.isEmpty) return const [];
    final perDay = (plan.dayProgram.length / plan.durationDays).ceil().clamp(
      1,
      plan.dayProgram.length,
    );
    final events = <TimelineEvent>[];
    for (var day = 0; day < plan.durationDays; day++) {
      final start = day * perDay;
      final end = math.min(start + perDay, plan.dayProgram.length);
      if (start >= plan.dayProgram.length) break;
      for (var i = start; i < end; i++) {
        events.add(
          TimelineEvent(
            dayOffset: day,
            type: TimelineEventType.activity,
            title: plan.dayProgram[i],
            subtitle: i < plan.dayDescriptions.length
                ? plan.dayDescriptions[i]
                : '',
            badge: l10n.reviewTimelineActivity,
          ),
        );
      }
    }
    return events;
  }
}

class _FlightsPanel extends StatelessWidget {
  const _FlightsPanel({required this.plan, required this.dates});

  final TripPlan plan;
  final (DateTime, DateTime) dates;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final route = _extractIata(plan.flightRoute, plan.flightDetails);
    final originCode =
        route?.$1 ?? (plan.originIata.isNotEmpty ? plan.originIata : '--');
    final destCode =
        route?.$2 ??
        (plan.destinationIata?.isNotEmpty == true
            ? plan.destinationIata!
            : '--');

    final outbound = BoardingPassModel(
      origin: originCode,
      destination: destCode,
      subtitle: plan.flightDetails.isEmpty
          ? plan.flightRoute
          : plan.flightDetails,
      departure:
          _parseTime(plan.flightDeparture) ??
          DateFormat('HH:mm').format(dates.$1),
      arrival:
          _parseTime(plan.flightArrival) ??
          DateFormat('HH:mm').format(dates.$1),
      airlineLine: [
        if (plan.flightAirline.isNotEmpty) plan.flightAirline,
        if (plan.flightNumber.isNotEmpty) plan.flightNumber,
        l10n.reviewFlightOutbound,
      ].join(' · '),
      flightDate: _formatFlightDate(plan.flightDeparture, dates.$1, locale),
    );
    final inbound = BoardingPassModel(
      origin: destCode,
      destination: originCode,
      subtitle: plan.flightRoute,
      departure:
          _parseTime(plan.returnDeparture) ??
          DateFormat('HH:mm').format(dates.$2),
      arrival:
          _parseTime(plan.returnArrival) ??
          DateFormat('HH:mm').format(dates.$2),
      airlineLine: [
        if (plan.flightAirline.isNotEmpty) plan.flightAirline,
        if (plan.flightNumber.isNotEmpty) plan.flightNumber,
        l10n.reviewFlightReturn,
      ].join(' · '),
      flightDate: _formatFlightDate(plan.returnDeparture, dates.$2, locale),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space8,
        AppSpacing.space16,
        AppSpacing.space16,
      ),
      children: [
        BoardingPassCard(title: l10n.reviewFlightOutbound, flight: outbound),
        const SizedBox(height: 16),
        BoardingPassCard(title: l10n.reviewFlightReturn, flight: inbound),
      ],
    );
  }

  String? _parseTime(String iso) {
    if (iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    return DateFormat('HH:mm').format(dt);
  }

  String _formatFlightDate(String iso, DateTime fallback, String locale) {
    final dt = iso.isNotEmpty ? (DateTime.tryParse(iso) ?? fallback) : fallback;
    return DateFormat('EEEE d MMM yyyy', locale).format(dt);
  }

  (String, String)? _extractIata(String route, String details) {
    final all = '$route $details';
    final regex = RegExp(r'([A-Z]{3})\s*[-–→]+\s*([A-Z]{3})');
    final match = regex.firstMatch(all);
    if (match == null) return null;
    return (match.group(1)!, match.group(2)!);
  }
}

class _HotelPanel extends StatelessWidget {
  const _HotelPanel({required this.plan, required this.dates});

  final TripPlan plan;
  final (DateTime, DateTime) dates;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nights = math.max(dates.$1.nightsUntil(dates.$2), 1);
    final perNight = plan.accommodationPrice > 0
        ? plan.accommodationPrice / nights
        : 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.large16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 88,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.reviewHeroDark, ColorName.primaryDark],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: plan.hotelRating > 0
                      ? List.generate(
                          plan.hotelRating,
                          (_) => const Icon(
                            Icons.star_rounded,
                            color: ColorName.surface,
                          ),
                        )
                      : const [
                          Icon(Icons.hotel_rounded, color: ColorName.surface),
                        ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.accommodationName,
                      style: const TextStyle(
                        fontFamily: FontFamily.dMSerifDisplay,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                    if (plan.accommodationSubtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        plan.accommodationSubtitle.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                          color: ColorName.hint,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.space16),
                    HotelStatsGrid(
                      entries: [
                        (
                          l10n.reviewHotelCheckIn,
                          DateFormat('d MMM').format(dates.$1),
                        ),
                        (
                          l10n.reviewHotelCheckOut,
                          DateFormat('d MMM').format(dates.$2),
                        ),
                        (l10n.reviewHotelNights, '$nights'),
                        (l10n.reviewHotelPerNight, perNight.formatPrice()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItineraryPanel extends StatelessWidget {
  const _ItineraryPanel({
    required this.dayProgram,
    required this.dayDescriptions,
    required this.dayCategories,
    required this.durationDays,
    required this.selectedDay,
    required this.onSelectDay,
  });

  final List<String> dayProgram;
  final List<String> dayDescriptions;
  final List<String> dayCategories;
  final int durationDays;
  final int selectedDay;
  final ValueChanged<int> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay();
    final maxDay = durationDays > 0 ? durationDays - 1 : 0;
    final safeDay = selectedDay.clamp(0, maxDay);
    final items = safeDay < grouped.length ? grouped[safeDay] : <int>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space12,
        AppSpacing.space16,
        AppSpacing.space16,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(durationDays, (index) {
              final active = index == safeDay;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () => onSelectDay(index),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? ColorName.primaryDark : ColorName.surface,
                    ),
                    child: Text(
                      'J${index + 1}',
                      style: TextStyle(
                        fontFamily: FontFamily.dMSerifDisplay,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: active ? ColorName.surface : ColorName.hint,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.space16),
        ...items.map(
          (index) => ActivityTile(
            title: dayProgram[index],
            description: index < dayDescriptions.length
                ? dayDescriptions[index]
                : '',
            category: index < dayCategories.length ? dayCategories[index] : '',
          ),
        ),
      ],
    );
  }

  List<List<int>> _groupByDay() {
    if (dayProgram.isEmpty || durationDays <= 0) {
      return List.filled(durationDays, []);
    }
    final perDay = (dayProgram.length / durationDays).ceil().clamp(
      1,
      dayProgram.length,
    );
    final groups = <List<int>>[];
    for (var d = 0; d < durationDays; d++) {
      final start = d * perDay;
      final end = math.min(start + perDay, dayProgram.length);
      if (start < dayProgram.length) {
        groups.add(List.generate(end - start, (i) => start + i));
      } else {
        groups.add([]);
      }
    }
    return groups;
  }
}

class _EssentialsPanel extends StatelessWidget {
  const _EssentialsPanel({
    required this.items,
    required this.reasons,
    required this.checked,
    required this.onToggle,
  });

  final List<String> items;
  final List<String> reasons;
  final Set<int> checked;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grouped = <String, List<int>>{};
    for (var i = 0; i < items.length; i++) {
      final key = _categoryForItem(items[i]);
      grouped.putIfAbsent(key, () => []).add(i);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
      ),
      children: grouped.entries.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                child: Text(
                  section.key.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: ColorName.hint,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.large24,
                  border: Border.all(color: ColorName.primarySoftLight),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  primary: false,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: section.value.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: ColorName.primarySoftLight,
                  ),
                  itemBuilder: (context, idx) {
                    final itemIndex = section.value[idx];
                    final reason = itemIndex < reasons.length
                        ? reasons[itemIndex]
                        : '';
                    return PackItem(
                      item: items[itemIndex],
                      reason: reason.isEmpty
                          ? ''
                          : l10n.reviewEssentialReason(reason),
                      checked: checked.contains(itemIndex),
                      onTap: () => onToggle(itemIndex),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _categoryForItem(String item) {
    final lower = item.toLowerCase();
    if (lower.contains('passeport') ||
        lower.contains('document') ||
        lower.contains('assurance')) {
      return 'Documents';
    }
    if (lower.contains('chaussure') ||
        lower.contains('veste') ||
        lower.contains('pull') ||
        lower.contains('manteau')) {
      return 'Vêtements';
    }
    if (lower.contains('adaptateur') ||
        lower.contains('batterie') ||
        lower.contains('chargeur')) {
      return 'Tech';
    }
    return 'Autres';
  }
}

class _BudgetPanel extends StatelessWidget {
  const _BudgetPanel({
    required this.total,
    required this.budgetBreakdown,
    required this.durationDays,
  });

  final double total;
  final Map<String, dynamic> budgetBreakdown;
  final int durationDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = extractBudgetEntries(l10n, budgetBreakdown);
    if (entries.isEmpty && total <= 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Text(
            l10n.reviewBudgetUnavailable,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              color: AppColors.reviewSubtle,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        BudgetStripe(
          total: total,
          entries: entries,
          subtitle:
              '${l10n.reviewBudgetEstimationPrefix} · ${l10n.summaryDaysCount(durationDays)}',
        ),
      ],
    );
  }
}
