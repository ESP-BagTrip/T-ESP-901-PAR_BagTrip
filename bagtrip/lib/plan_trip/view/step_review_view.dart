import 'dart:math' as math;

import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
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
    with SingleTickerProviderStateMixin {
  final Set<int> _checkedEssentials = {};
  late final TabController _tabController;
  bool _ctaPressed = false;
  int _selectedJourneyDay = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
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

        return ColoredBox(
          color: ColorName.surfaceVariant,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _ReviewHero(
                  city: plan.destinationCity,
                  daysLabel: l10n.summaryDaysCount(plan.durationDays),
                  budgetLabel: l10n.summaryBudgetAmount('${plan.budgetEur}€'),
                  dateRangeLabel: _formatDateRange(context, dates),
                  onEditDates: () => _showDateEditor(context, state),
                ),
                const SizedBox(height: AppSpacing.space12),
                _PanelChipsBar(labels: panels, controller: _tabController),
                const SizedBox(height: AppSpacing.space12),
                Expanded(
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
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                  decoration: const BoxDecoration(
                    color: ColorName.surface,
                    border: Border(top: BorderSide(color: ColorName.hint)),
                  ),
                  child: Column(
                    children: [
                      _CreateTripButton(
                        isCreating: state.isCreating,
                        isPressed: _ctaPressed,
                        onPressStart: () => setState(() => _ctaPressed = true),
                        onPressEnd: () => setState(() => _ctaPressed = false),
                        onTap: () {
                          AppHaptics.medium();
                          context.read<PlanTripBloc>().add(
                            const PlanTripEvent.createTrip(),
                          );
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<PlanTripBloc>().add(
                            const PlanTripEvent.backToProposals(),
                          );
                        },
                        child: Text(
                          l10n.reviewSeeOtherDestinations,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            color: Color(0xFF7C7A75),
                          ),
                        ),
                      ),
                      SizedBox(height: AdaptivePlatform.isIOS ? 20 : 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
  });

  final String city;
  final String daysLabel;
  final String dateRangeLabel;
  final String budgetLabel;
  final VoidCallback onEditDates;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 192,
      width: double.infinity,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorName.primaryDark,
                    Color(0xCC0D3055),
                    Colors.transparent,
                  ],
                  stops: [0, 0.68, 1],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            left: 24,
            right: 24,
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
                const SizedBox(),
                InkWell(
                  onTap: onEditDates,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                      const SizedBox(),
                      Text(
                        dateRangeLabel,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSerifDisplay,
                          fontStyle: FontStyle.italic,
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
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
      decoration: const BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.pill,
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
        ),
        labelStyle: const TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelColor: ColorName.hint,
        labelColor: ColorName.surface,
        dividerColor: Colors.transparent,
        indicator: const BoxDecoration(
          color: ColorName.primaryDark,
          borderRadius: AppRadius.pill,
        ),
        tabs: labels.map((label) => Tab(text: label)).toList(),
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
    final route = _extractIata(plan.flightRoute, plan.flightDetails);
    final outbound = _FlightModel(
      origin: route?.$1 ?? 'CDG',
      destination: route?.$2 ?? 'KIX',
      subtitle: plan.flightDetails.isEmpty
          ? plan.flightRoute
          : plan.flightDetails,
      departure: DateFormat('HH:mm').format(dates.$1),
      arrival: DateFormat(
        'HH:mm',
      ).format(dates.$1.add(const Duration(hours: 8))),
    );
    final inbound = _FlightModel(
      origin: route?.$2 ?? 'KIX',
      destination: route?.$1 ?? 'CDG',
      subtitle: plan.flightRoute,
      departure: DateFormat(
        'HH:mm',
      ).format(dates.$2.subtract(const Duration(hours: 8))),
      arrival: DateFormat('HH:mm').format(dates.$2),
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
                        "AIR FRANCE · AF 006 · ALLER".toUpperCase(),
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
                        ),
                      ),
                      Expanded(
                        child: _FlightMeta(
                          label: l10n.reviewFlightArrival,
                          value: flight.arrival,
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
  });

  final String origin;
  final String destination;
  final String subtitle;
  final String departure;
  final String arrival;
}

class _FlightMeta extends StatelessWidget {
  const _FlightMeta({required this.label, required this.value});
  final String label;
  final String value;

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
          "Lundi 14 Avr 2026".toUpperCase(),
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
                child: const Row(
                  children: [
                    Icon(Icons.star_rounded, color: ColorName.surface),
                    Icon(Icons.star_rounded, color: ColorName.surface),
                    Icon(Icons.star_rounded, color: ColorName.surface),
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

          const Text(
            "Après 16:00",
            style: TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorName.hint,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: grouped.entries.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  section.key.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF9A9893),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0x1A000000)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: section.value.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0x12000000)),
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
                      fontFamily: FontFamily.b612,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (reason.isNotEmpty)
                    Text(
                      reason,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0x66000000),
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
  const _BudgetPanel({required this.total, required this.budgetBreakdown});

  final double total;
  final Map<String, dynamic> budgetBreakdown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = _extractEntries(l10n, budgetBreakdown);
    final resolvedEntries = entries.isEmpty ? _prototypeEntries(l10n) : entries;
    final sum = resolvedEntries.fold<double>(
      0,
      (value, entry) => value + entry.amount,
    );
    final resolvedTotal = total > 0 ? total : sum;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        Center(
          child: Text(
            '${resolvedTotal.toStringAsFixed(0)} €',
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 68,
              color: Color(0xFF171513),
              height: 1,
            ),
          ),
        ),
        Center(
          child: Text(
            l10n.reviewBudgetTotal,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              color: Color(0xFF928F89),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...resolvedEntries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.medium8,
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: entry.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.label,
                      style: const TextStyle(fontFamily: FontFamily.b612),
                    ),
                  ),
                  Text(
                    '${sum > 0 ? ((entry.amount / sum) * 100).round() : 0}%',
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      color: Color(0xFF8F8D88),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${entry.amount.toStringAsFixed(0)} €',
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
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
    'flights' => ColorName.primaryDark,
    'accommodation' => ColorName.primary,
    'meals' => ColorName.secondary,
    'transport' => ColorName.secondary,
    'activities' => const Color(0xFF5A7A9A),
    _ => const Color(0xFF8B8882),
  };

  List<_BudgetEntry> _prototypeEntries(AppLocalizations l10n) => [
    _BudgetEntry(
      label: l10n.reviewBudgetFlights,
      amount: 650,
      color: ColorName.primaryDark,
    ),
    _BudgetEntry(
      label: l10n.reviewBudgetAccommodation,
      amount: 980,
      color: ColorName.primary,
    ),
    _BudgetEntry(
      label: l10n.reviewBudgetMeals,
      amount: 280,
      color: ColorName.secondary,
    ),
    _BudgetEntry(
      label: l10n.reviewBudgetActivities,
      amount: 320,
      color: ColorName.secondary,
    ),
  ];
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
          height: 56,
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
                    fontFamily: FontFamily.b612,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
        ),
      ),
    );
  }
}
