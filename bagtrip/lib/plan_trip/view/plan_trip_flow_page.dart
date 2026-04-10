import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/premium_step_indicator.dart';
import 'package:bagtrip/design/widgets/step_header.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/helpers/traveler_breakdown_format.dart';
import 'package:bagtrip/plan_trip/models/budget_preset.dart';
import 'package:bagtrip/plan_trip/models/date_mode.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/plan_trip/view/step_ai_proposals_view.dart';
import 'package:bagtrip/plan_trip/view/step_dates_view.dart';
import 'package:bagtrip/plan_trip/view/step_destination_view.dart';
import 'package:bagtrip/plan_trip/view/step_generation_view.dart';
import 'package:bagtrip/plan_trip/view/step_review_view.dart';
import 'package:bagtrip/plan_trip/view/step_travelers_budget_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
          final isGenerationStep = state.currentStep == 4;
          final showWizardIndicator = state.currentStep < 4;
          final indicatorCurrent = (state.currentStep + 1).clamp(1, 4).toInt();

          final isReviewStep = state.currentStep == 5;

          return Scaffold(
            backgroundColor: isReviewStep
                ? ColorName.surfaceVariant
                : PersonalizationColors.gradientStart,
            body: SafeArea(
              top: !isReviewStep,
              bottom: !isReviewStep,
              left: false,
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isReviewStep)
                    _WizardNavAnimatedColumn(
                      currentStep: state.currentStep,
                      totalSteps: state.totalSteps,
                      title: _stepTitle(state.currentStep, l10n),
                      showBack: state.currentStep > 0,
                      showStepIndicator: showWizardIndicator,
                      indicatorCurrent: indicatorCurrent,
                      indicatorTotal: 4,
                      onBack: () {
                        if (isGenerationStep) {
                          context.read<PlanTripBloc>().add(
                            const PlanTripEvent.backToProposals(),
                          );
                          return;
                        }
                        context.read<PlanTripBloc>().add(
                          const PlanTripEvent.previousStep(),
                        );
                      },
                      onClose: () {
                        if (isGenerationStep) {
                          context.read<PlanTripBloc>().add(
                            const PlanTripEvent.backToProposals(),
                          );
                        }
                        const HomeRoute().go(context);
                      },
                    ),
                  if (state.currentStep > 0 && state.currentStep < 4)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                      ),
                      child: StepHeader(
                        enrichedSplitCollapsed: state.currentStep == 2,
                        items: _buildSummaryItems(context, state, l10n),
                      ),
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
    BuildContext context,
    PlanTripState state,
    AppLocalizations l10n,
  ) {
    final items = <StepSummaryItem>[];
    if (state.currentStep > 0 && state.areDatesValid) {
      items.add(
        StepSummaryItem(
          icon: Icons.calendar_today_rounded,
          label: l10n.datesLabel,
          value: _datesPrimaryLine(state, l10n),
          subtitle: _datesSubtitleLine(state, context),
        ),
      );
    }
    if (state.currentStep > 1) {
      items.add(
        StepSummaryItem(
          icon: Icons.people_outline_rounded,
          label: l10n.travelersLabel,
          value: l10n.travelerCountLabel(state.nbTravelers),
          subtitle: formatTravelerBreakdownDetail(
            l10n,
            nbAdults: state.nbAdults,
            nbChildren: state.nbChildren,
            nbBabies: state.nbBabies,
          ),
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

  String _datesPrimaryLine(PlanTripState state, AppLocalizations l10n) {
    if (state.dateMode == DateMode.exact &&
        state.startDate != null &&
        state.endDate != null) {
      final days = state.endDate!.difference(state.startDate!).inDays;
      final nights = days > 0 ? days - 1 : 0;
      return l10n.planTripDurationDaysNights(days, nights);
    }
    return _datesSummary(state, l10n);
  }

  String? _datesSubtitleLine(PlanTripState state, BuildContext context) {
    if (state.dateMode == DateMode.exact &&
        state.startDate != null &&
        state.endDate != null) {
      final locale = Localizations.localeOf(context).toString();
      final fmt = DateFormat.yMMMd(locale);
      return '${fmt.format(state.startDate!)} → ${fmt.format(state.endDate!)}';
    }
    return null;
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

class _WizardNavAnimatedColumn extends StatefulWidget {
  const _WizardNavAnimatedColumn({
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.showBack,
    required this.showStepIndicator,
    required this.indicatorCurrent,
    required this.indicatorTotal,
    required this.onBack,
    required this.onClose,
  });

  final int currentStep;
  final int totalSteps;
  final String title;
  final bool showBack;
  final bool showStepIndicator;
  final int indicatorCurrent;
  final int indicatorTotal;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  State<_WizardNavAnimatedColumn> createState() =>
      _WizardNavAnimatedColumnState();
}

class _WizardNavAnimatedColumnState extends State<_WizardNavAnimatedColumn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fadeDown,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.standardCurve,
    );
    _slide = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppAnimations.standardCurve,
          ),
        );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _WizardNavAnimatedColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space4,
            AppSpacing.space16,
            0,
          ),
          child: Column(
            children: [
              SizedBox(
                height: kToolbarHeight - 8,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.showBack) ...[
                            _PlanTripBackButton(onPressed: widget.onBack),
                            const SizedBox(width: AppSpacing.space8),
                          ],
                          _PlanTripCloseButton(onPressed: widget.onClose),
                          const SizedBox(width: AppSpacing.space8),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: PersonalizationColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showStepIndicator)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: PremiumStepIndicator(
                    current: widget.indicatorCurrent,
                    total: widget.indicatorTotal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanTripCloseButton extends StatelessWidget {
  const _PlanTripCloseButton({required this.onPressed});

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
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: ColorName.secondary.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.close_rounded,
            size: 20,
            color: PersonalizationColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PlanTripBackButton extends StatelessWidget {
  const _PlanTripBackButton({required this.onPressed});

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
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: ColorName.secondary.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 22,
            color: PersonalizationColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
