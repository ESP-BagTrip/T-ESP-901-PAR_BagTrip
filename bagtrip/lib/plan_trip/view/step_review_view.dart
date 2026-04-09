import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:bagtrip/plan_trip/widgets/accommodation_preview_card.dart';
import 'package:intl/intl.dart';
import 'package:bagtrip/plan_trip/widgets/budget_breakdown_chart.dart';
import 'package:bagtrip/plan_trip/widgets/day_activities_tab.dart';
import 'package:bagtrip/plan_trip/widgets/flight_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class StepReviewView extends StatefulWidget {
  const StepReviewView({super.key});

  @override
  State<StepReviewView> createState() => _StepReviewViewState();
}

class _StepReviewViewState extends State<StepReviewView> {
  final Set<int> _checkedEssentials = {};
  bool _ctaPressed = false;

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
          return _buildShimmer();
        }

        return CustomScrollView(
          slivers: [
            // Hero SliverAppBar
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              stretch: true,
              automaticallyImplyLeading: false,
              backgroundColor: PersonalizationColors.accentBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: PersonalizationColors.accentGradient,
                        ),
                      ),
                    ),
                    // Dark overlay at bottom
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                          stops: [0.4, 1.0],
                        ),
                      ),
                    ),
                    // Content overlay
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space22,
                        0,
                        AppSpacing.space22,
                        AppSpacing.space24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.destinationCity,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space4),
                          Text(
                            plan.destinationCountry,
                            style: TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 18,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space12),
                          // Info chips row
                          Wrap(
                            spacing: AppSpacing.space8,
                            children: [
                              _FrostedChip(
                                icon: Icons.calendar_today_rounded,
                                label: l10n.summaryDaysCount(plan.durationDays),
                              ),
                              _FrostedChip(
                                icon: Icons.account_balance_wallet_outlined,
                                label: l10n.summaryBudgetAmount(
                                  '${plan.budgetEur}€',
                                ),
                              ),
                              if (plan.weatherData.isNotEmpty)
                                _FrostedChip(
                                  icon: Icons.wb_sunny_rounded,
                                  label: _weatherLabel(plan.weatherData),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Body content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.space24),

                    // Highlights
                    if (plan.highlights.isNotEmpty) ...[
                      StaggeredFadeIn(
                        index: 0,
                        child: _SectionLabel(label: l10n.reviewHighlightsLabel),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      StaggeredFadeIn(
                        index: 0,
                        child: Wrap(
                          spacing: AppSpacing.space8,
                          runSpacing: AppSpacing.space8,
                          children: plan.highlights
                              .map((h) => _HighlightChip(label: h))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space24),
                    ],

                    // Dates section
                    StaggeredFadeIn(
                      index: 0,
                      child: _SectionLabel(label: l10n.reviewSectionDates),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    StaggeredFadeIn(
                      index: 0,
                      child: _DatesSummaryCard(
                        dates: state.representativeDates,
                        isRepresentative: state.areDatesRepresentative,
                        onEdit: () => _showDateEditor(context, state),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space24),

                    // Flight section
                    if (plan.flightRoute.isNotEmpty) ...[
                      StaggeredFadeIn(
                        index: 1,
                        child: _SectionLabel(label: l10n.summarySectionFlight),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      FlightPreviewCard(
                        route: plan.flightRoute,
                        details: plan.flightDetails,
                        price: plan.flightPrice,
                        source: plan.flightSource,
                        animationIndex: 1,
                      ),
                      const SizedBox(height: AppSpacing.space24),
                    ],

                    // Accommodation section
                    if (plan.accommodationName.isNotEmpty) ...[
                      StaggeredFadeIn(
                        index: 2,
                        child: _SectionLabel(
                          label: l10n.summarySectionWhereStay,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      AccommodationPreviewCard(
                        name: plan.accommodationName,
                        subtitle: plan.accommodationSubtitle,
                        price: plan.accommodationPrice,
                        source: plan.accommodationSource,
                        animationIndex: 2,
                      ),
                      const SizedBox(height: AppSpacing.space24),
                    ],

                    // Day-by-day section
                    if (plan.dayProgram.isNotEmpty) ...[
                      StaggeredFadeIn(
                        index: 3,
                        child: _SectionLabel(
                          label: l10n.summarySectionYourJourney,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      StaggeredFadeIn(
                        index: 3,
                        child: DayActivitiesTab(
                          dayProgram: plan.dayProgram,
                          dayDescriptions: plan.dayDescriptions,
                          dayCategories: plan.dayCategories,
                          durationDays: plan.durationDays,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space24),
                    ],

                    // Essentials section
                    if (plan.essentialItems.isNotEmpty) ...[
                      StaggeredFadeIn(
                        index: 4,
                        child: _SectionLabel(
                          label: l10n.summarySectionEssentials,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      ...plan.essentialItems.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final reason = i < plan.essentialReasons.length
                            ? plan.essentialReasons[i]
                            : '';
                        return StaggeredFadeIn(
                          index: 4 + i,
                          child: _EssentialRow(
                            item: item,
                            reason: reason,
                            checked: _checkedEssentials.contains(i),
                            onToggle: () {
                              AppHaptics.light();
                              setState(() {
                                if (_checkedEssentials.contains(i)) {
                                  _checkedEssentials.remove(i);
                                } else {
                                  _checkedEssentials.add(i);
                                }
                              });
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: AppSpacing.space24),
                    ],

                    // Budget breakdown section
                    if (plan.budgetBreakdown.isNotEmpty) ...[
                      StaggeredFadeIn(
                        index: 5,
                        child: _SectionLabel(label: l10n.reviewSectionBudget),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      BudgetBreakdownChart(
                        budgetBreakdown: plan.budgetBreakdown,
                        animationIndex: 5,
                      ),
                      const SizedBox(height: AppSpacing.space32),
                    ],

                    // CTA — Create trip
                    StaggeredFadeIn(
                      index: 6,
                      child: _CreateTripButton(
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
                    ),
                    const SizedBox(height: AppSpacing.space12),

                    // See other destinations link
                    StaggeredFadeIn(
                      index: 6,
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            context.read<PlanTripBloc>().add(
                              const PlanTripEvent.backToProposals(),
                            );
                          },
                          child: Text(
                            l10n.reviewSeeOtherDestinations,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 14,
                              color: PersonalizationColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom padding
                    SizedBox(
                      height: AdaptivePlatform.isIOS ? 100 : AppSpacing.space48,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space22),
      child: Column(
        children: [
          // Hero shimmer
          Shimmer.fromColors(
            baseColor: ColorName.shimmerBase,
            highlightColor: ColorName.shimmerHighlight,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                color: ColorName.primaryLight,
                borderRadius: AppRadius.large16,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space24),
          // Cards shimmer
          for (var i = 0; i < 3; i++) ...[
            Shimmer.fromColors(
              baseColor: ColorName.shimmerBase,
              highlightColor: ColorName.shimmerHighlight,
              child: Container(
                height: 88,
                margin: AppSpacing.onlyBottomSpace16,
                decoration: const BoxDecoration(
                  color: ColorName.primaryLight,
                  borderRadius: AppRadius.large16,
                ),
              ),
            ),
          ],
          // Chart shimmer
          Shimmer.fromColors(
            baseColor: ColorName.shimmerBase,
            highlightColor: ColorName.shimmerHighlight,
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                color: ColorName.primaryLight,
                borderRadius: AppRadius.large16,
              ),
            ),
          ),
        ],
      ),
    );
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

  String _weatherLabel(Map<String, dynamic> weather) {
    final temp = weather['avg_temp_c'] ?? weather['temperature'];
    if (temp != null) return '$temp°C';
    final condition = weather['condition'] ?? weather['description'];
    if (condition != null) return condition.toString();
    return '';
  }
}

// ─── Private widgets ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: FontFamily.b612,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: PersonalizationColors.textTertiary,
      ),
    );
  }
}

class _FrostedChip extends StatelessWidget {
  const _FrostedChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: AppRadius.pill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatesSummaryCard extends StatelessWidget {
  const _DatesSummaryCard({
    required this.dates,
    required this.isRepresentative,
    required this.onEdit,
  });

  final (DateTime, DateTime) dates;
  final bool isRepresentative;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final fmt = DateFormat('d MMM yyyy', locale);
    final (start, end) = dates;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: ColorName.surface,
          borderRadius: AppRadius.large16,
          border: Border.all(color: ColorName.primarySoftLight),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${fmt.format(start)} — ${fmt.format(end)}',
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PersonalizationColors.textPrimary,
                    ),
                  ),
                  if (isRepresentative) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.reviewDatesSuggested,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 11,
                        color: PersonalizationColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              size: 16,
              color: PersonalizationColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: PersonalizationColors.chipSelected,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: FontFamily.b612,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: PersonalizationColors.accentBlue,
        ),
      ),
    );
  }
}

class _EssentialRow extends StatelessWidget {
  const _EssentialRow({
    required this.item,
    required this.reason,
    required this.checked,
    required this.onToggle,
  });

  final String item;
  final String reason;
  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: InkWell(
        onTap: onToggle,
        borderRadius: AppRadius.medium8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: checked
                  ? const Icon(
                      Icons.check_circle_rounded,
                      key: ValueKey('checked'),
                      size: 22,
                      color: AppColors.success,
                    )
                  : const Icon(
                      Icons.radio_button_unchecked_rounded,
                      key: ValueKey('unchecked'),
                      size: 22,
                      color: PersonalizationColors.textTertiary,
                    ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PersonalizationColors.textPrimary,
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.reviewEssentialReason(reason),
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: PersonalizationColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        scale: isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: PersonalizationColors.accentGradient,
            ),
            borderRadius: AppRadius.pill,
            boxShadow: [
              BoxShadow(
                color: PersonalizationColors.accentBlue.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isCreating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    l10n.reviewCreateTrip,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
