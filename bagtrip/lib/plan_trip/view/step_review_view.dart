import 'dart:math' as math;

import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
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
  static const Duration _footerVisibilityDuration = Duration(milliseconds: 280);
  static const double _scrollDeltaThreshold = 3;

  final Set<int> _checkedEssentials = {};
  late final TabController _tabController;
  late final AnimationController _footerVisibilityController;
  late final CurvedAnimation _footerVisibilityCurve;
  bool _ctaPressed = false;
  int _selectedJourneyDay = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onReviewTabChanged);
    _footerVisibilityController = AnimationController(
      vsync: this,
      duration: _footerVisibilityDuration,
      value: 1,
    );
    _footerVisibilityCurve = CurvedAnimation(
      parent: _footerVisibilityController,
      curve: Curves.easeInOut,
    );
  }

  void _onReviewTabChanged() {
    if (_tabController.indexIsChanging) return;
    _footerVisibilityController.forward();
  }

  bool _onReviewScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is! ScrollUpdateNotification) return false;
    final delta = notification.scrollDelta;
    if (delta == null || delta.abs() < _scrollDeltaThreshold) return false;
    if (delta > 0) {
      _footerVisibilityController.reverse();
    } else {
      _footerVisibilityController.forward();
    }
    return false;
  }

  @override
  void dispose() {
    _tabController.removeListener(_onReviewTabChanged);
    _footerVisibilityCurve.dispose();
    _footerVisibilityController.dispose();
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
            _ReviewHero(
              city: plan.destinationCity,
              daysLabel: l10n.summaryDaysCount(plan.durationDays),
              budgetLabel: l10n.summaryBudgetAmount('${plan.budgetEur}€'),
              dateRangeLabel: _formatDateRange(context, dates),
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
                child: _PanelChipsBar(
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
                        onNotification: _onReviewScrollNotification,
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
                  AnimatedBuilder(
                    animation: _footerVisibilityCurve,
                    builder: (context, child) {
                      return IgnorePointer(
                        ignoring: _footerVisibilityCurve.value < 0.01,
                        child: child,
                      );
                    },
                    child: FadeTransition(
                      opacity: _footerVisibilityCurve,
                      child: SizeTransition(
                        sizeFactor: _footerVisibilityCurve,
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CreateTripButton(
                                  isCreating: state.isCreating,
                                  isPressed: _ctaPressed,
                                  onPressStart: () =>
                                      setState(() => _ctaPressed = true),
                                  onPressEnd: () =>
                                      setState(() => _ctaPressed = false),
                                  onTap: () {
                                    AppHaptics.medium();
                                    context.read<PlanTripBloc>().add(
                                      const PlanTripEvent.createTrip(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
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

class _ReviewHero extends StatelessWidget {
  const _ReviewHero({
    required this.city,
    required this.daysLabel,
    required this.dateRangeLabel,
    required this.budgetLabel,
    required this.onEditDates,
    required this.onBack,
    required this.onClose,
  });

  final String city;
  final String daysLabel;
  final String dateRangeLabel;
  final String budgetLabel;
  final VoidCallback onEditDates;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return DecoratedBox(
      decoration: const BoxDecoration(color: ColorName.primaryDark),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                AppSpacing.space4,
                AppSpacing.space16,
                0,
              ),
              child: Row(
                children: [
                  _HeroNavButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBack,
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  _HeroNavButton(icon: Icons.close_rounded, onPressed: onClose),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      city,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: FontFamily.dMSerifDisplay,
                        fontSize: 24,
                        color: ColorName.surface,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onEditDates,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          daysLabel.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontWeight: FontWeight.w700,
                            color: ColorName.hint,
                          ),
                        ),
                        Text(
                          dateRangeLabel,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontSize: 16,
                            color: ColorName.surface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          budgetLabel,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: ColorName.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroNavButton extends StatelessWidget {
  const _HeroNavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: AppSpacing.space40,
          height: AppSpacing.space40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: ColorName.surface),
        ),
      ),
    );
  }
}

class _PanelChipsBar extends StatelessWidget {
  const _PanelChipsBar({required this.labels, required this.controller});

  final List<String> labels;
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
      decoration: const BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.pill,
      ),
      child: TabBar(
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: const TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelColor: ColorName.hint,
        labelColor: ColorName.surface,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const BoxDecoration(
          color: ColorName.primaryDark,
          borderRadius: AppRadius.pill,
        ),
        tabs: labels.map((label) => Tab(height: 36, text: label)).toList(),
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.plan, required this.dates});

  final TripPlan plan;
  final (DateTime, DateTime) dates;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final events = <_TimelineEvent>[
      if (plan.flightRoute.isNotEmpty)
        _TimelineEvent(
          dayOffset: 0,
          type: EventType.flight,
          title: plan.flightRoute,
          subtitle: plan.flightDetails,
          badge: l10n.reviewTimelineFlight,
        ),
      if (plan.accommodationName.isNotEmpty)
        _TimelineEvent(
          dayOffset: 0,
          type: EventType.hotel,
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
          return _TimelineCard(
            event: _TimelineEvent(
              dayOffset: math.max(plan.durationDays - 1, 0),
              type: EventType.hotel,
              title: l10n.reviewTimelineCheckOut,
              subtitle: DateFormat('d MMM').format(dates.$2),
              badge: l10n.reviewTabHotel,
            ),
            firstDate: dates.$1,
          );
        }
        return _TimelineCard(event: events[index], firstDate: dates.$1);
      },
    );
  }

  List<_TimelineEvent> _buildActivityEvents(
    TripPlan plan,
    AppLocalizations l10n,
  ) {
    if (plan.dayProgram.isEmpty) return const [];
    final perDay = (plan.dayProgram.length / plan.durationDays).ceil().clamp(
      1,
      plan.dayProgram.length,
    );
    final events = <_TimelineEvent>[];
    for (var day = 0; day < plan.durationDays; day++) {
      final start = day * perDay;
      final end = math.min(start + perDay, plan.dayProgram.length);
      if (start >= plan.dayProgram.length) break;
      for (var i = start; i < end; i++) {
        events.add(
          _TimelineEvent(
            dayOffset: day,
            type: EventType.activity,
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

enum EventType { flight, hotel, activity }

class _TimelineEvent {
  const _TimelineEvent({
    required this.dayOffset,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final int dayOffset;
  final EventType type;
  final String title;
  final String subtitle;
  final String badge;
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.event, required this.firstDate});

  final _TimelineEvent event;
  final DateTime firstDate;

  @override
  Widget build(BuildContext context) {
    final date = firstDate.add(Duration(days: event.dayOffset));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(height: 18, width: 1, color: const Color(0x22000000)),
              _TlDot(type: event.type),
              Container(height: 74, width: 1, color: const Color(0x22000000)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space16),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.large24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE d MMM').format(date).toUpperCase(),
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ColorName.hint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ColorName.primaryDark,
                    ),
                  ),
                  if (event.subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      event.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        color: Color(0xFF8D8B86),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TlDot extends StatelessWidget {
  const _TlDot({required this.type});

  final EventType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      EventType.flight => ColorName.primaryDark,
      EventType.hotel => ColorName.primary,
      EventType.activity => ColorName.secondary,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
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

    final outbound = _FlightModel(
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
    final inbound = _FlightModel(
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
        _BoardingPassCard(title: l10n.reviewFlightOutbound, flight: outbound),
        const SizedBox(height: 16),
        _BoardingPassCard(title: l10n.reviewFlightReturn, flight: inbound),
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

class _BoardingPassCard extends StatelessWidget {
  const _BoardingPassCard({required this.title, required this.flight});

  final String title;
  final _FlightModel flight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: AppRadius.large16,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Container(
              color: ColorName.primaryDark,
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        flight.airlineLine.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 1,
                          color: ColorName.hint,
                        ),
                      ),
                    ],
                  ),
                  // const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        flight.origin,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSerifDisplay,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: ColorName.surface,
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: ColorName.hint,
                          indent: 10,
                          endIndent: 10,
                        ),
                      ),
                      Text(
                        flight.destination,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSerifDisplay,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: ColorName.surface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Column(
                children: [
                  if (flight.subtitle.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        flight.subtitle,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          color: ColorName.hint,
                        ),
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: _FlightMeta(
                          label: l10n.reviewFlightDeparture,
                          value: flight.departure,
                          date: flight.flightDate,
                        ),
                      ),
                      Expanded(
                        child: _FlightMeta(
                          label: l10n.reviewFlightArrival,
                          value: flight.arrival,
                          date: flight.flightDate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlightModel {
  const _FlightModel({
    required this.origin,
    required this.destination,
    required this.subtitle,
    required this.departure,
    required this.arrival,
    required this.airlineLine,
    required this.flightDate,
  });

  final String origin;
  final String destination;
  final String subtitle;
  final String departure;
  final String arrival;
  final String airlineLine;
  final String flightDate;
}

class _FlightMeta extends StatelessWidget {
  const _FlightMeta({
    required this.label,
    required this.value,
    required this.date,
  });
  final String label;
  final String value;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: FontFamily.dMSans,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 1,
            color: ColorName.hint,
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontFamily: FontFamily.dMSerifDisplay,
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: ColorName.primaryDark,
          ),
        ),

        const SizedBox(height: AppSpacing.space4),
        Text(
          date.toUpperCase(),
          style: const TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
            color: ColorName.hint,
          ),
        ),
      ],
    );
  }
}

class _HotelPanel extends StatelessWidget {
  const _HotelPanel({required this.plan, required this.dates});

  final TripPlan plan;
  final (DateTime, DateTime) dates;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nights = math.max(dates.$2.difference(dates.$1).inDays, 1);
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
                    colors: [Color(0xFF123D6A), ColorName.primaryDark],
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
                    _HotelStatsGrid(
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
                        (
                          l10n.reviewHotelPerNight,
                          '${perNight.toStringAsFixed(0)} €',
                        ),
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

class _HotelStatsGrid extends StatelessWidget {
  const _HotelStatsGrid({required this.entries});
  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 4) {
      return const SizedBox.shrink();
    }
    final firstRow = entries.take(2).toList(growable: false);
    final secondRow = entries.skip(2).take(2).toList(growable: false);
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _HotelStatBox(entry: firstRow[0])),
              const SizedBox(width: AppSpacing.space8),
              Expanded(child: _HotelStatBox(entry: firstRow[1])),
            ],
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _HotelStatBox(entry: secondRow[0])),
              const SizedBox(width: 8),
              Expanded(child: _HotelStatBox(entry: secondRow[1])),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotelStatBox extends StatelessWidget {
  const _HotelStatBox({required this.entry});

  final (String, String) entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: const BoxDecoration(
        color: ColorName.surfaceLight,
        borderRadius: AppRadius.large16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.$1.toUpperCase(),
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: ColorName.hint,
            ),
          ),

          const SizedBox(height: AppSpacing.space4),
          Text(
            entry.$2,
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorName.primaryDark,
            ),
          ),
        ],
      ),
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
          (index) => _ActivityTile(
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

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.description,
    required this.category,
  });

  final String title;
  final String description;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: const BoxDecoration(
          color: ColorName.surface,
          borderRadius: AppRadius.large16,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ColorName.primary.withValues(alpha: 0.18),
                borderRadius: AppRadius.large16,
              ),
              child: Text(_categoryEmoji(category)),
            ),
            const SizedBox(width: AppSpacing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: ColorName.primaryDark,
                    ),
                  ),
                  if (description.isNotEmpty)
                    const SizedBox(height: AppSpacing.space4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ColorName.hint,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space12,
                vertical: AppSpacing.space8,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.pill,
                color: ColorName.secondary.withValues(alpha: 0.12),
              ),
              child: Text(
                category.isEmpty ? 'ACT' : category.toUpperCase(),
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: ColorName.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String raw) {
    final key = raw.toLowerCase();
    if (key.contains('culture') || key.contains('museum')) return '🏛️';
    if (key.contains('nature') || key.contains('park')) return '🌿';
    if (key.contains('food') || key.contains('restaurant')) return '🍽️';
    if (key.contains('shopping')) return '🛍️';
    return '📍';
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
                    return _PackItem(
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

class _PackItem extends StatelessWidget {
  const _PackItem({
    required this.item,
    required this.reason,
    required this.checked,
    required this.onTap,
  });

  final String item;
  final String reason;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              checked
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: checked ? ColorName.secondary : const Color(0xFFC8C5BE),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      color: ColorName.primaryDark,
                    ),
                  ),
                  if (reason.isNotEmpty)
                    const SizedBox(height: AppSpacing.space4),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ColorName.hint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  static const _ink = Color(0xFF171513);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = _extractEntries(l10n, budgetBreakdown);
    if (entries.isEmpty && total <= 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Text(
            l10n.reviewBudgetUnavailable,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              color: Color(0xFF928F89),
            ),
          ),
        ),
      );
    }
    final resolvedEntries = entries;
    final sum = resolvedEntries.fold<double>(
      0,
      (value, entry) => value + entry.amount,
    );
    final resolvedTotal = total > 0 ? total : sum;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${resolvedTotal.toStringAsFixed(0)} €',
                      style: const TextStyle(
                        fontFamily: FontFamily.dMSerifDisplay,
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                        color: _ink,
                        height: 1,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${l10n.reviewBudgetEstimationPrefix} · ${l10n.summaryDaysCount(durationDays)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: _ink.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
                if (resolvedEntries.isNotEmpty && sum > 0)
                  Container(
                    height: 6,
                    margin: const EdgeInsets.only(top: 12, bottom: 14),
                    child: Row(
                      children: [
                        for (var i = 0; i < resolvedEntries.length; i++)
                          Expanded(
                            flex: ((resolvedEntries[i].amount / sum) * 1000)
                                .round()
                                .clamp(1, 1000),
                            child: _BudgetSegment(
                              color: resolvedEntries[i].color,
                              isFirst: i == 0,
                              isLast: i == resolvedEntries.length - 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ...resolvedEntries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.5),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: entry.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.label,
                            style: TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: _ink.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        Text(
                          '${entry.amount.toStringAsFixed(0)} €',
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const _categoryKeys = [
    'flights',
    'accommodation',
    'meals',
    'transport',
    'activities',
  ];

  List<_BudgetEntry> _extractEntries(
    AppLocalizations l10n,
    Map<String, dynamic> breakdown,
  ) {
    final entries = <_BudgetEntry>[];
    for (final key in _categoryKeys) {
      final value = breakdown[key];
      double? amount;
      if (value is Map) {
        final raw = value['amount'];
        if (raw is num) amount = raw.toDouble();
      } else if (value is num) {
        amount = value.toDouble();
      }
      if (amount == null || amount <= 0) continue;
      entries.add(
        _BudgetEntry(
          label: _labelForKey(key, l10n),
          amount: amount,
          color: _colorForKey(key),
        ),
      );
    }
    return entries;
  }

  static String _labelForKey(String key, AppLocalizations l10n) =>
      switch (key) {
        'flights' => l10n.reviewBudgetFlights,
        'accommodation' => l10n.reviewBudgetAccommodation,
        'meals' => l10n.reviewBudgetMeals,
        'transport' => l10n.reviewBudgetTransport,
        'activities' => l10n.reviewBudgetActivities,
        _ => l10n.reviewBudgetOther,
      };

  static Color _colorForKey(String key) => switch (key) {
    'flights' => ColorName.primary,
    'accommodation' => ColorName.primaryDark,
    'meals' => ColorName.warning,
    'transport' => const Color(0xFFE8A4B8),
    'activities' => ColorName.secondary,
    _ => const Color(0xFF8B8882),
  };
}

class _BudgetSegment extends StatelessWidget {
  const _BudgetSegment({
    required this.color,
    required this.isFirst,
    required this.isLast,
  });

  final Color color;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(100) : Radius.zero,
          right: isLast ? const Radius.circular(100) : Radius.zero,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BudgetEntry {
  const _BudgetEntry({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;
}

class _CreateTripButton extends StatelessWidget {
  const _CreateTripButton({
    required this.isCreating,
    required this.isPressed,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onTap,
  });

  final bool isCreating;
  final bool isPressed;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTapDown: (_) => onPressStart(),
      onTapUp: (_) {
        onPressEnd();
        if (!isCreating) onTap();
      },
      onTapCancel: onPressEnd,
      child: AnimatedScale(
        scale: isPressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 140),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: const BoxDecoration(
            color: ColorName.primaryDark,
            borderRadius: AppRadius.pill,
          ),
          alignment: Alignment.center,
          child: isCreating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : Text(
                  l10n.reviewCreateTrip,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
