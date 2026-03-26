import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/widgets/premium_step_indicator.dart';
import 'package:bagtrip/design/widgets/step_header.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:bagtrip/plan_trip/models/budget_preset.dart';
import 'package:bagtrip/plan_trip/view/step_dates_view.dart';
import 'package:bagtrip/plan_trip/view/step_destination_view.dart';
import 'package:bagtrip/plan_trip/view/step_ai_proposals_view.dart';
import 'package:bagtrip/plan_trip/view/step_generation_view.dart';
import 'package:bagtrip/plan_trip/view/step_review_view.dart';
import 'package:bagtrip/plan_trip/view/step_travelers_budget_view.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlanTripFlowPage extends StatefulWidget {
  const PlanTripFlowPage({super.key, this.initialDestination});

  final LocationResult? initialDestination;

  @override
  State<PlanTripFlowPage> createState() => _PlanTripFlowPageState();
}

class _PlanTripFlowPageState extends State<PlanTripFlowPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) {
        final bloc = PlanTripBloc();
        if (widget.initialDestination != null) {
          bloc.add(
            PlanTripEvent.selectManualDestination(widget.initialDestination!),
          );
        }
        return bloc;
      },
      child: BlocConsumer<PlanTripBloc, PlanTripState>(
        listenWhen: (prev, curr) =>
            prev.currentStep != curr.currentStep ||
            prev.createdTripId != curr.createdTripId,
        listener: (context, state) {
          if (_pageController.hasClients &&
              _pageController.page?.round() != state.currentStep) {
            _pageController.animateToPage(
              state.currentStep,
              duration: AppAnimations.wizardTransition,
              curve: AppAnimations.springCurve,
            );
          }

          // Auto-fire generation when entering step 4
          if (state.currentStep == 4 && state.generationSteps.isEmpty) {
            context.read<PlanTripBloc>().add(
              const PlanTripEvent.startGeneration(),
            );
          }

          if (state.createdTripId != null && state.createdTripId!.isNotEmpty) {
            AppHaptics.success();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.tripCreatedSuccess)));
            TripHomeRoute(tripId: state.createdTripId!).go(context);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: PersonalizationColors.gradientStart,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: () => const HomeRoute().go(context),
              ),
              title: Text(
                _stepTitle(state.currentStep, l10n),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: FontFamily.b612,
                  fontSize: 16,
                  color: PersonalizationColors.textPrimary,
                ),
              ),
              centerTitle: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: PersonalizationColors.gradientStart,
              foregroundColor: PersonalizationColors.textPrimary,
            ),
            body: SafeArea(
              left: false,
              right: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: PremiumStepIndicator(
                      current: state.currentStep + 1,
                      total: state.totalSteps,
                    ),
                  ),
                  if (state.currentStep > 0 && state.currentStep < 4)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: StepHeader(items: _buildSummaryItems(state, l10n)),
                    ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        StepDatesView(),
                        StepTravelersBudgetView(),
                        StepDestinationView(),
                        StepAiProposalsView(),
                        StepGenerationView(),
                        StepReviewView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _stepTitle(int step, AppLocalizations l10n) {
    return switch (step) {
      0 => l10n.planTripStepDates,
      1 => l10n.stepTravelers,
      2 => l10n.stepDestination,
      3 => l10n.stepAiProposals,
      4 => l10n.stepGeneration,
      5 => l10n.stepReview,
      _ => '',
    };
  }

  List<StepSummaryItem> _buildSummaryItems(
    PlanTripState state,
    AppLocalizations l10n,
  ) {
    final items = <StepSummaryItem>[];
    if (state.currentStep > 0 && state.areDatesValid) {
      items.add(
        StepSummaryItem(
          icon: Icons.calendar_today_rounded,
          label: l10n.datesLabel,
          value: _datesSummary(state, l10n),
        ),
      );
    }
    if (state.currentStep > 1) {
      items.add(
        StepSummaryItem(
          icon: Icons.people_outline_rounded,
          label: l10n.travelersLabel,
          value: l10n.travelerCountLabel(state.nbTravelers),
        ),
      );
      if (state.budgetPreset != null) {
        items.add(
          StepSummaryItem(
            icon: Icons.account_balance_wallet_outlined,
            label: l10n.budgetLabel,
            value: _budgetPresetLabel(state.budgetPreset!, l10n),
          ),
        );
      }
    }
    if (state.currentStep > 2 && state.isDestinationValid) {
      final destName =
          state.selectedManualDestination?.name ??
          state.selectedAiDestination?.city ??
          '';
      if (destName.isNotEmpty) {
        items.add(
          StepSummaryItem(
            icon: Icons.place_outlined,
            label: l10n.stepDestination,
            value: destName,
          ),
        );
      }
    }
    return items;
  }

  String _datesSummary(PlanTripState state, AppLocalizations l10n) {
    if (state.startDate != null && state.endDate != null) {
      return '${state.endDate!.difference(state.startDate!).inDays} ${l10n.days}';
    }
    if (state.flexibleDuration != null) {
      return switch (state.flexibleDuration!) {
        DurationPreset.weekend => l10n.datesFlexibleWeekend,
        DurationPreset.oneWeek => l10n.datesFlexibleWeek,
        DurationPreset.twoWeeks => l10n.datesFlexibleTwoWeeks,
        DurationPreset.threeWeeks => l10n.datesFlexibleThreeWeeks,
      };
    }
    if (state.preferredMonth != null) {
      return l10n.datesModeMonth;
    }
    return '';
  }

  String _budgetPresetLabel(BudgetPreset preset, AppLocalizations l10n) {
    return switch (preset) {
      BudgetPreset.backpacker => l10n.budgetPresetBackpacker,
      BudgetPreset.comfortable => l10n.budgetPresetComfortable,
      BudgetPreset.premium => l10n.budgetPresetPremium,
      BudgetPreset.noLimit => l10n.budgetPresetNoLimit,
    };
  }
}
