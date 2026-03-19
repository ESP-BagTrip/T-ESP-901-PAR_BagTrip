import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/widgets/premium_step_indicator.dart';
import 'package:bagtrip/design/widgets/step_header.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:bagtrip/plan_trip/view/step_dates_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlanTripFlowPage extends StatefulWidget {
  const PlanTripFlowPage({super.key});

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
      create: (_) => PlanTripBloc(),
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

          if (state.createdTripId != null && state.createdTripId!.isNotEmpty) {
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
                  if (state.currentStep > 0)
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
                        Center(child: Text('Step 1')),
                        Center(child: Text('Step 2')),
                        Center(child: Text('Step 3')),
                        Center(child: Text('Step 4')),
                        Center(child: Text('Step 5')),
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
      3 => l10n.stepReview,
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
}
