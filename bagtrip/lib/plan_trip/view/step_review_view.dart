import 'dart:math' as math;

import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/widgets/review/review_budget_reveal.dart';
import 'package:bagtrip/design/widgets/review/review_cinematic_hero.dart';
import 'package:bagtrip/design/widgets/review/review_day_card.dart';
import 'package:bagtrip/design/widgets/review/review_day_timeline.dart';
import 'package:bagtrip/design/widgets/review/review_decision_inline.dart';
import 'package:bagtrip/design/widgets/review/review_inline_flight.dart';
import 'package:bagtrip/design/widgets/review/review_inline_hotel.dart';
import 'package:bagtrip/design/widgets/review/review_recommendation_section.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/helpers/budget_breakdown.dart';
import 'package:bagtrip/plan_trip/helpers/destination_cover.dart';
import 'package:bagtrip/plan_trip/models/trip_plan.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Editorial single-scroll review page — the user reads the trip like a
/// proposition and decides at the end (after the budget reveal). Replaces
/// the tab-based [PanelChipsBar] layout that treated browsing as decision.
class StepReviewView extends StatelessWidget {
  const StepReviewView({super.key});

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

        final dates = state.representativeDates;
        final locale = Localizations.localeOf(context).languageCode;
        final days = _buildDayCards(context, plan, dates, l10n);

        return ColoredBox(
          color: AppColors.surfaceVariant,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReviewCinematicHero(
                  city: plan.destinationCity,
                  country: plan.destinationCountry,
                  coverImageUrl: _resolveCoverUrl(plan, state),
                  dateRangeLabel: _formatDateRange(dates, locale),
                  durationLabel: l10n.summaryDaysCount(plan.durationDays),
                  travelersLabel: l10n.reviewSummaryTravelers(
                    state.nbTravelers,
                  ),
                  onBack: () => context.read<PlanTripBloc>().add(
                    const PlanTripEvent.backToProposals(),
                  ),
                  onClose: () => const HomeRoute().go(context),
                ),
                ReviewDayTimeline(
                  days: days,
                  freeDayLabel: l10n.reviewDayFree,
                  dayTitleBuilder: (data) =>
                      l10n.reviewDayTitle(data.dayNumber, data.dateLabel),
                ),
                ReviewRecommendationSection(
                  title: l10n.reviewMealsToTry,
                  icon: Icons.restaurant_rounded,
                  recommendations: plan.mealRecommendations,
                ),
                ReviewRecommendationSection(
                  title: l10n.reviewTransportTips,
                  icon: Icons.directions_transit_rounded,
                  recommendations: plan.transportRecommendations,
                ),
                ReviewBudgetReveal(
                  header: l10n.reviewBudgetHeader,
                  perPersonLabel: _perPersonLabel(
                    plan.budgetEur,
                    state.nbTravelers,
                    l10n,
                  ),
                  total: plan.budgetEur,
                  entries: extractBudgetEntries(
                    l10n,
                    plan.budgetBreakdown,
                    accommodationDeferred: plan.accommodationName.isEmpty,
                  ),
                  subtitle:
                      '${l10n.reviewBudgetEstimationPrefix} · '
                      '${l10n.summaryDaysCount(plan.durationDays)}',
                ),
                ReviewDecisionInline(
                  header: l10n.reviewDecisionHeader.toUpperCase(),
                  primaryLabel: l10n.reviewDecisionPrimary,
                  secondaryLabel: l10n.reviewSeeOtherDestinations,
                  isPrimaryLoading: state.isCreating,
                  onPrimary: state.isCreating
                      ? null
                      : () {
                          AppHaptics.medium();
                          context.read<PlanTripBloc>().add(
                            const PlanTripEvent.createTrip(),
                          );
                        },
                  onSecondary: state.isCreating
                      ? null
                      : () => context.read<PlanTripBloc>().add(
                          const PlanTripEvent.backToProposals(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _resolveCoverUrl(TripPlan plan, PlanTripState state) {
    final aiImage = state.selectedAiDestination?.imageUrl;
    if (aiImage != null && aiImage.isNotEmpty) return aiImage;
    return destinationCoverUrl(
      city: plan.destinationCity,
      country: plan.destinationCountry,
    );
  }

  // --------------------------------------------------------------------------
  // Builders
  // --------------------------------------------------------------------------

  List<ReviewDayCardData> _buildDayCards(
    BuildContext context,
    TripPlan plan,
    (DateTime, DateTime) dates,
    AppLocalizations l10n,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final dayFmt = DateFormat('EEE d MMM', locale);
    final duration = math.max(plan.durationDays, 1);
    final activityGroups = _groupActivitiesByDay(plan, duration);

    final outbound = _buildOutboundFlight(plan, l10n);
    final inbound = _buildReturnFlight(plan, l10n);
    final hotel = _buildHotelArrival(plan, duration, l10n);

    return List.generate(duration, (index) {
      final flights = <ReviewInlineFlightData>[];
      if (index == 0 && outbound != null) flights.add(outbound);
      if (index == duration - 1 && inbound != null) flights.add(inbound);

      return ReviewDayCardData(
        dayNumber: index + 1,
        dateLabel: dayFmt.format(dates.$1.add(Duration(days: index))),
        flights: flights,
        hotelArrival: index == 0 ? hotel : null,
        activities: activityGroups[index],
      );
    });
  }

  List<List<ReviewDayActivity>> _groupActivitiesByDay(
    TripPlan plan,
    int duration,
  ) {
    if (plan.dayProgram.isEmpty) {
      return List.generate(duration, (_) => <ReviewDayActivity>[]);
    }
    final perDay = (plan.dayProgram.length / duration).ceil().clamp(
      1,
      plan.dayProgram.length,
    );
    return List.generate(duration, (day) {
      final start = day * perDay;
      if (start >= plan.dayProgram.length) return <ReviewDayActivity>[];
      final end = math.min(start + perDay, plan.dayProgram.length);
      return [
        for (var i = start; i < end; i++)
          ReviewDayActivity(
            title: plan.dayProgram[i],
            description: i < plan.dayDescriptions.length
                ? plan.dayDescriptions[i]
                : '',
          ),
      ];
    });
  }

  ReviewInlineFlightData? _buildOutboundFlight(
    TripPlan plan,
    AppLocalizations l10n,
  ) {
    if (plan.flightRoute.isEmpty &&
        plan.originIata.isEmpty &&
        (plan.destinationIata?.isEmpty ?? true)) {
      return null;
    }
    final iata = _extractIata(plan.flightRoute, plan.flightDetails);
    final origin = iata?.$1 ?? plan.originIata;
    final dest = iata?.$2 ?? (plan.destinationIata ?? '');
    return ReviewInlineFlightData(
      originIata: origin,
      destinationIata: dest,
      departureTime: _formatTime(plan.flightDeparture),
      arrivalTime: _formatTime(plan.flightArrival),
      durationLabel: _formatDuration(plan.flightDuration, l10n),
      airline: _composeAirlineLine(plan),
      priceLabel: plan.flightPrice > 0 ? plan.flightPrice.formatPrice() : '',
      tagLabel: l10n.reviewFlightOutbound,
    );
  }

  ReviewInlineFlightData? _buildReturnFlight(
    TripPlan plan,
    AppLocalizations l10n,
  ) {
    final hasReturnData =
        plan.returnDeparture.isNotEmpty || plan.returnArrival.isNotEmpty;
    final hasOutboundData =
        plan.flightRoute.isNotEmpty ||
        plan.originIata.isNotEmpty ||
        (plan.destinationIata?.isNotEmpty ?? false);
    // If we have an outbound there's always a return — show it even when
    // Amadeus didn't surface specific return-leg timestamps. Times render as
    // em-dash placeholders and the user can validate / edit later.
    if (!hasReturnData && !hasOutboundData) return null;
    final iata = _extractIata(plan.flightRoute, plan.flightDetails);
    final origin = iata?.$1 ?? plan.originIata;
    final dest = iata?.$2 ?? (plan.destinationIata ?? '');
    return ReviewInlineFlightData(
      originIata: dest,
      destinationIata: origin,
      departureTime: _formatTime(plan.returnDeparture),
      arrivalTime: _formatTime(plan.returnArrival),
      durationLabel: _formatDuration(plan.returnDuration, l10n),
      airline: _composeAirlineLine(plan),
      priceLabel: '',
      tagLabel: l10n.reviewFlightReturn,
    );
  }

  ReviewInlineHotelData? _buildHotelArrival(
    TripPlan plan,
    int durationDays,
    AppLocalizations l10n,
  ) {
    final hasRealHotel = plan.accommodationName.isNotEmpty;
    final hasDates = durationDays > 0;
    if (!hasRealHotel && !hasDates) return null;

    if (hasRealHotel) {
      return ReviewInlineHotelData(
        name: plan.accommodationName,
        rating: plan.hotelRating,
        arrivalLabel: l10n.reviewHotelArrival,
        staySummary: l10n.reviewHotelStayNights(durationDays),
        subtitle: plan.accommodationSubtitle,
      );
    }

    // Deferred-marker case: backend could not retrieve a real hotel
    // (Amadeus down, niche city). Render a clear placeholder instead
    // of fabricating a name + per-night price the user would mis-read
    // as a stay total.
    final destName = plan.destinationCity.isNotEmpty
        ? plan.destinationCity
        : (plan.destinationIata ?? '');
    return ReviewInlineHotelData(
      name: l10n.accommodationToBeChosen,
      rating: 0,
      arrivalLabel: l10n.reviewHotelArrival,
      staySummary: l10n.reviewHotelStayNights(durationDays),
      subtitle: l10n.accommodationDeferredSubtitle(
        destName,
        l10n.reviewHotelStayNights(durationDays),
      ),
    );
  }

  String _composeAirlineLine(TripPlan plan) {
    final parts = <String>[
      if (plan.flightAirline.isNotEmpty) plan.flightAirline,
      if (plan.flightNumber.isNotEmpty) plan.flightNumber,
    ];
    if (parts.isEmpty && plan.flightDetails.isNotEmpty) {
      return plan.flightDetails;
    }
    return parts.join(' · ');
  }

  // --------------------------------------------------------------------------
  // Formatters
  // --------------------------------------------------------------------------

  String _formatDateRange((DateTime, DateTime) dates, String locale) {
    final sameMonth =
        dates.$1.month == dates.$2.month && dates.$1.year == dates.$2.year;
    if (sameMonth) {
      final day = DateFormat('d', locale);
      final tail = DateFormat('d MMM', locale);
      return '${day.format(dates.$1)} — ${tail.format(dates.$2)}';
    }
    final fmt = DateFormat('d MMM', locale);
    return '${fmt.format(dates.$1)} — ${fmt.format(dates.$2)}';
  }

  String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('HH:mm').format(dt);
  }

  /// Parses an ISO 8601 duration ("PT2H20M", "PT45M") into a localized
  /// "{h}h{mm}" label. Returns empty string on failure.
  String _formatDuration(String iso, AppLocalizations l10n) {
    if (iso.isEmpty) return '';
    final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?').firstMatch(iso);
    if (match == null) return '';
    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    if (hours == 0 && minutes == 0) return '';
    return l10n.reviewFlightDurationHm(
      hours,
      minutes.toString().padLeft(2, '0'),
    );
  }

  (String, String)? _extractIata(String route, String details) {
    final all = '$route $details';
    final regex = RegExp(r'([A-Z]{3})\s*[-–→]+\s*([A-Z]{3})');
    final match = regex.firstMatch(all);
    if (match == null) return null;
    return (match.group(1)!, match.group(2)!);
  }

  String _perPersonLabel(
    double budgetTotal,
    int travelers,
    AppLocalizations l10n,
  ) {
    if (travelers <= 1 || budgetTotal <= 0) return '';
    final perPerson = budgetTotal / travelers;
    return l10n.reviewBudgetPerPerson(perPerson.formatPrice());
  }
}
