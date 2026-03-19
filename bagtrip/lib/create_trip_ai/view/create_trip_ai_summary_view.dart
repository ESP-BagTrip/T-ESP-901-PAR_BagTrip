import 'package:bagtrip/create_trip_ai/bloc/create_trip_ai_bloc.dart';
import 'package:bagtrip/create_trip_ai/models/trip_summary.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/assets.gen.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Category icon mapping for activity categories.
IconData _categoryIcon(String category) {
  return switch (category.toUpperCase()) {
    'CULTURE' => Icons.museum,
    'NATURE' => Icons.park,
    'FOOD' => Icons.restaurant,
    'SPORT' => Icons.fitness_center,
    'SHOPPING' => Icons.shopping_bag,
    'NIGHTLIFE' => Icons.nightlife,
    'RELAXATION' => Icons.spa,
    _ => Icons.place,
  };
}

class CreateTripAiSummaryView extends StatefulWidget {
  const CreateTripAiSummaryView({super.key});

  @override
  State<CreateTripAiSummaryView> createState() =>
      _CreateTripAiSummaryViewState();
}

class _CreateTripAiSummaryViewState extends State<CreateTripAiSummaryView> {
  /// Local state for essentials checklist (checked indices).
  final Set<int> _essentialChecked = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTripAiBloc, CreateTripAiState>(
      builder: (context, state) {
        if (state is CreateTripAiSearchLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        if (state is CreateTripAiStreaming) {
          return _buildStreamingView(context, state);
        }
        if (state is CreateTripAiSummaryLoaded) {
          return _buildSummary(context, state.summary);
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator.adaptive()),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Streaming progress view
  // ---------------------------------------------------------------------------

  Widget _buildStreamingView(
    BuildContext context,
    CreateTripAiStreaming state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: ColorName.surfaceLight,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.allEdgeInsetSpace24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(height: AppSpacing.space24),
              Text(
                state.message.isNotEmpty ? state.message : l10n.summarySaveTrip,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorName.primaryTrueDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space16),
              // Show what data has arrived
              _buildStreamingProgress(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingProgress(CreateTripAiStreaming state) {
    return Column(
      children: [
        _streamingStep(
          'Destinations',
          Icons.flight_takeoff,
          state.destinations != null,
        ),
        _streamingStep(
          'Activities',
          Icons.local_activity,
          state.activities != null,
        ),
        _streamingStep(
          'Accommodation',
          Icons.hotel,
          state.accommodations != null,
        ),
        _streamingStep(
          'Packing list',
          Icons.luggage,
          state.baggageItems != null,
        ),
        _streamingStep(
          'Budget',
          Icons.account_balance_wallet,
          state.budgetEstimation != null,
        ),
      ],
    );
  }

  Widget _streamingStep(String label, IconData icon, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? ColorName.success : ColorName.hint,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.space8),
          Icon(
            icon,
            color: done ? ColorName.primary : ColorName.hint,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.space8),
          Text(
            label,
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 14,
              color: done ? ColorName.primaryTrueDark : ColorName.hint,
              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Full summary view (after streaming completes)
  // ---------------------------------------------------------------------------

  Widget _buildSummary(BuildContext context, TripSummary s) {
    return Scaffold(
      backgroundColor: ColorName.surfaceLight,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            _buildUpcomingJourney(context, s),
            SliverToBoxAdapter(child: _buildWhiteSheet(context, s)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingJourney(BuildContext context, TripSummary s) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.paddingOf(context).top;

    return SliverToBoxAdapter(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Image.asset(
              Assets.images.parisMockPicture.path,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2A4A6E).withValues(alpha: 0.3),
                    const Color(0xFF1F3A5F).withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.space8,
              right: AppSpacing.space24,
              top: topPadding + AppSpacing.space8,
              bottom: AppSpacing.space24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Container(
                    padding: AppSpacing.allEdgeInsetSpace8,
                    decoration: BoxDecoration(
                      color: ColorName.surface.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: ColorName.surface,
                      size: 24,
                    ),
                  ),
                  onPressed: () => context.read<CreateTripAiBloc>().add(
                    CreateTripAiLoadRecap(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.space16,
                    right: AppSpacing.space8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        s.destination,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: ColorName.surface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        s.destinationCountry,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: ColorName.surface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      Row(
                        children: [
                          _upcomingChip(
                            icon: Icons.calendar_today_rounded,
                            label: l10n.summaryDaysCount(s.durationDays),
                          ),
                          const SizedBox(width: AppSpacing.space8),
                          _upcomingChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: l10n.summaryBudgetAmount(
                              _formatBudget(s.budgetEur),
                            ),
                          ),
                          if (s.weatherData.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.space8),
                            _upcomingChip(
                              icon: Icons.thermostat,
                              label:
                                  '${(s.weatherData['avg_temp_c'] ?? '').toString()}°C',
                            ),
                          ],
                        ],
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

  String _formatBudget(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')},${value % 1000 == 0 ? '000' : value % 1000}';
    }
    return value.toString();
  }

  Widget _upcomingChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space8,
      ),
      decoration: const BoxDecoration(
        color: ColorName.primary,
        borderRadius: AppRadius.medium8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ColorName.primaryLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 13,
              color: ColorName.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteSheet(BuildContext context, TripSummary s) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: ColorName.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: AppSpacing.horizontalSpace16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.space12),
            _sheetSectionLabel(l10n.summarySectionCurated),
            const SizedBox(height: AppSpacing.space4),
            Text(
              l10n.summaryTripHighlights,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Wrap(
              spacing: AppSpacing.space8,
              runSpacing: AppSpacing.space8,
              children: s.highlights.map((h) => _highlightChip(h)).toList(),
            ),
            const SizedBox(height: AppSpacing.space24),
            _sheetSectionLabel(l10n.summarySectionWhereStay),
            const SizedBox(height: AppSpacing.space4),
            Text(
              l10n.summaryAccommodation,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            _buildAccommodationCard(context, l10n, s),
            const SizedBox(height: AppSpacing.space24),
            _sheetSectionLabel(l10n.summarySectionFlight),
            const SizedBox(height: AppSpacing.space4),
            Text(
              l10n.summaryFlight,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            _buildFlightCard(context, l10n, s),
            const SizedBox(height: AppSpacing.space24),
            _sheetSectionLabel(l10n.summarySectionYourJourney),
            const SizedBox(height: AppSpacing.space4),
            Text(
              l10n.summaryDayByDay,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            _buildDayByDayTimeline(context, l10n, s),
            const SizedBox(height: AppSpacing.space24),
            _sheetSectionLabel(l10n.summarySectionEssentials),
            const SizedBox(height: AppSpacing.space4),
            Text(
              l10n.summaryWhatToBring,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            _buildEssentialsList(context, l10n, s),
            const SizedBox(height: AppSpacing.space32),
            _buildSaveButton(context, l10n),
            const SizedBox(height: AppSpacing.space8),
            _buildRegenerateButton(context, l10n),
            const SizedBox(height: AppSpacing.space48),
          ],
        ),
      ),
    );
  }

  Widget _sheetSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: FontFamily.b612,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ColorName.textMutedLight,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _highlightChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: ColorName.surfaceLight,
        borderRadius: AppRadius.medium8,
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '◆ ',
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 12,
              color: ColorName.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 13,
              color: ColorName.primaryTrueDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Source badge — "Amadeus" (verified) or "Estimated".
  Widget _sourceBadge(String source) {
    final isVerified = source.toLowerCase() == 'amadeus';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: isVerified
            ? ColorName.success.withValues(alpha: 0.2)
            : ColorName.warning.withValues(alpha: 0.2),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        isVerified ? 'Verified' : 'Estimated',
        style: TextStyle(
          fontFamily: FontFamily.b612,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isVerified ? ColorName.success : ColorName.warning,
        ),
      ),
    );
  }

  Widget _buildAccommodationCard(
    BuildContext context,
    AppLocalizations l10n,
    TripSummary s,
  ) {
    final subtitle = s.accommodationSubtitle.isNotEmpty
        ? s.accommodationSubtitle
        : '${s.destination} · ${s.accommodationPrice.toStringAsFixed(0)} EUR';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
        boxShadow: [
          BoxShadow(
            color: ColorName.primarySoftLight.withValues(alpha: 0.5),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 80,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(2)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ColorName.primary, ColorName.secondary],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: ColorName.primaryLight,
              borderRadius: AppRadius.medium8,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.home_rounded, color: ColorName.primary),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        s.accommodation,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ColorName.primaryTrueDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    _sourceBadge(s.accommodationSource),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    color: ColorName.textMutedLight,
                  ),
                ),
                if (s.accommodationPrice > 0) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    '${s.accommodationPrice.toStringAsFixed(0)} EUR total',
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorName.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard(
    BuildContext context,
    AppLocalizations l10n,
    TripSummary s,
  ) {
    final route = s.flightRoute.isNotEmpty
        ? s.flightRoute
        : l10n.summaryFlightRouteMock;
    final details = s.flightDetails.isNotEmpty
        ? s.flightDetails
        : l10n.summaryFlightDetailsMock;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
        boxShadow: [
          BoxShadow(
            color: ColorName.primarySoftLight.withValues(alpha: 0.5),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 80,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(2)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ColorName.primary, ColorName.secondary],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: ColorName.primaryLight,
              borderRadius: AppRadius.medium8,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.flight_rounded, color: ColorName.primary),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        route,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ColorName.primaryTrueDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    _sourceBadge(s.flightSource),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  details,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    color: ColorName.textMutedLight,
                  ),
                ),
                if (s.flightPrice > 0) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    '${s.flightPrice.toStringAsFixed(0)} EUR',
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorName.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayByDayTimeline(
    BuildContext context,
    AppLocalizations l10n,
    TripSummary s,
  ) {
    final count = s.dayByDayProgram.length;
    if (count == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.space8),
      child: Column(
        children: List.generate(count, (i) {
          final isLast = i == count - 1;
          final description = i < s.dayByDayDescriptions.length
              ? s.dayByDayDescriptions[i]
              : '';
          final category = i < s.dayByDayCategories.length
              ? s.dayByDayCategories[i]
              : '';

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: ColorName.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${l10n.summaryDayPrefix}${i + 1}',
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ColorName.surface,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: AppSpacing.verticalSpace4,
                          color: ColorName.primarySoftLight,
                        ),
                      )
                    else
                      const SizedBox(height: AppSpacing.space24),
                  ],
                ),
                const SizedBox(width: AppSpacing.space16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.dayByDayProgram[i],
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ColorName.primaryTrueDark,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.space4),
                          Text(
                            description,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 13,
                              color: ColorName.textMutedLight,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (category.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.space8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: const BoxDecoration(
                              color: ColorName.surfaceVariant,
                              borderRadius: AppRadius.pill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _categoryIcon(category),
                                  size: 14,
                                  color: ColorName.textMutedLight,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontFamily: FontFamily.b612,
                                    fontSize: 12,
                                    color: ColorName.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEssentialsList(
    BuildContext context,
    AppLocalizations l10n,
    TripSummary s,
  ) {
    if (s.essentialItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.large16,
        child: Column(
          children: List.generate(s.essentialItems.length, (i) {
            final checked = _essentialChecked.contains(i);
            final reason = i < s.essentialReasons.length
                ? s.essentialReasons[i]
                : '';

            return InkWell(
              onTap: () {
                setState(() {
                  if (checked) {
                    _essentialChecked.remove(i);
                  } else {
                    _essentialChecked.add(i);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: i < s.essentialItems.length - 1
                      ? const Border(
                          bottom: BorderSide(color: ColorName.primarySoftLight),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: checked ? ColorName.success : Colors.transparent,
                        border: Border.all(
                          color: checked ? ColorName.success : ColorName.border,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: checked
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: ColorName.surface,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.essentialItems[i],
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 14,
                              color: ColorName.primaryTrueDark,
                            ),
                          ),
                          if (reason.isNotEmpty)
                            Text(
                              reason,
                              style: const TextStyle(
                                fontFamily: FontFamily.b612,
                                fontSize: 12,
                                color: ColorName.textMutedLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: AppSpacing.space56,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<CreateTripAiBloc>().add(
              CreateTripAiAcceptSuggestion(),
            );
          },
          borderRadius: AppRadius.large16,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorName.primary, ColorName.secondary],
              ),
              borderRadius: AppRadius.large16,
            ),
            alignment: Alignment.center,
            child: Text(
              l10n.summarySaveTrip,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorName.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegenerateButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: AppSpacing.space56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          context.read<CreateTripAiBloc>().add(CreateTripAiRegenerate());
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: ColorName.primarySoftLight),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large16),
        ),
        child: Text(
          l10n.summaryRegenerate,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorName.primaryTrueDark,
          ),
        ),
      ),
    );
  }
}
