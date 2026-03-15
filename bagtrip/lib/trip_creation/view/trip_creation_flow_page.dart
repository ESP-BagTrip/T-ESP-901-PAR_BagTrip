import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_creation/bloc/trip_creation_bloc.dart';
import 'package:bagtrip/trip_creation/view/step_dates_view.dart';
import 'package:bagtrip/trip_creation/view/step_destination_view.dart';
import 'package:bagtrip/trip_creation/view/step_review_view.dart';
import 'package:bagtrip/trip_creation/view/step_travelers_view.dart';
import 'package:bagtrip/trip_creation/widgets/step_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripCreationFlowPage extends StatefulWidget {
  const TripCreationFlowPage({super.key});

  @override
  State<TripCreationFlowPage> createState() => _TripCreationFlowPageState();
}

class _TripCreationFlowPageState extends State<TripCreationFlowPage> {
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
      create: (context) => TripCreationBloc(),
      child: BlocConsumer<TripCreationBloc, TripCreationState>(
        listenWhen: (prev, curr) =>
            prev.currentStep != curr.currentStep ||
            prev.createdTripId != curr.createdTripId,
        listener: (context, state) {
          // Animate page on step change
          if (_pageController.hasClients &&
              _pageController.page?.round() != state.currentStep) {
            _pageController.animateToPage(
              state.currentStep,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          }

          // Navigate to trip home on creation success
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
                    child: StepIndicator(currentStep: state.currentStep),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        StepDestinationView(),
                        StepDatesView(),
                        StepTravelersView(),
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
      0 => l10n.stepDestination,
      1 => l10n.stepDates,
      2 => l10n.stepTravelers,
      3 => l10n.stepReview,
      _ => '',
    };
  }
}
