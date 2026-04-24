import 'dart:async';

import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/destination_carousel.dart';
import 'package:bagtrip/design/widgets/progression_cta_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/widgets/ai_destination_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StepAiProposalsView extends StatefulWidget {
  const StepAiProposalsView({super.key});

  @override
  State<StepAiProposalsView> createState() => _StepAiProposalsViewState();
}

class _StepAiProposalsViewState extends State<StepAiProposalsView>
    with TickerProviderStateMixin {
  late final AnimationController _selectionController;
  late final CurvedAnimation _scaleAnim;
  late final CurvedAnimation _overlayAnim;
  late final CurvedAnimation _fadeOthersAnim;

  int? _selectedCardIndex;
  bool _swipeHintVisible = true;
  Timer? _swipeHintTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _selectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener(_onSelectionComplete);

    _scaleAnim = CurvedAnimation(
      parent: _selectionController,
      curve: const Interval(0.0, 0.25, curve: AppAnimations.springCurve),
    );
    _overlayAnim = CurvedAnimation(
      parent: _selectionController,
      curve: const Interval(0.25, 0.5, curve: AppAnimations.standardCurve),
    );
    _fadeOthersAnim = CurvedAnimation(
      parent: _selectionController,
      curve: const Interval(0.5, 0.75, curve: AppAnimations.standardCurve),
    );

    _swipeHintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _swipeHintVisible = false);
    });
  }

  @override
  void dispose() {
    _swipeHintTimer?.cancel();
    _scaleAnim.dispose();
    _overlayAnim.dispose();
    _fadeOthersAnim.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  void _onSelectionComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      context.read<PlanTripBloc>().add(
        PlanTripEvent.swipeProposal(_currentPage),
      );
    }
  }

  void _onChoose() {
    // Double-tap guard
    if (_selectedCardIndex != null) return;

    AppHaptics.success();
    setState(() => _selectedCardIndex = _currentPage);
    _selectionController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<PlanTripBloc, PlanTripState>(
      builder: (context, state) {
        if (state.aiSuggestions.isEmpty) {
          return ElegantEmptyState(
            icon: Icons.auto_awesome_rounded,
            title: l10n.aiProposalsEmpty,
            subtitle: l10n.aiProposalsEmptySubtitle,
            ctaLabel: l10n.backButton,
            onCta: () => context.read<PlanTripBloc>().add(
              const PlanTripEvent.previousStep(),
            ),
          );
        }

        final showSwipeHint =
            _swipeHintVisible && state.aiSuggestions.length > 1;

        return AnimatedBuilder(
          animation: _selectionController,
          builder: (context, _) {
            return Column(
              children: [
                // Section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space22,
                    AppSpacing.space22,
                    AppSpacing.space22,
                    0,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: ColorName.secondary,
                      ),
                      const SizedBox(width: AppSpacing.space8),
                      Text(
                        l10n.stepAiProposals,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ColorName.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Carousel
                Expanded(
                  child: DestinationCarousel(
                    itemCount: state.aiSuggestions.length,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCardIndex == index;
                      final isOther = _selectedCardIndex != null && !isSelected;

                      // Scale selected card
                      final scale = isSelected
                          ? 1.0 + 0.05 * _scaleAnim.value
                          : 1.0;
                      // Fade non-selected cards
                      final opacity = isOther
                          ? 1.0 - 0.7 * _fadeOthersAnim.value
                          : 1.0;
                      // Overlay progress for selected card
                      final overlayProgress = isSelected
                          ? _overlayAnim.value
                          : 0.0;

                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: AiDestinationCard(
                            destination: state.aiSuggestions[index],
                            selectionProgress: overlayProgress,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Swipe hint
                AnimatedOpacity(
                  opacity: showSwipeHint ? 1.0 : 0.0,
                  duration: AppAnimations.fadeIn,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space8),
                    child: Text(
                      l10n.swipeToDiscover,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: ColorName.hint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // "Choose this destination" CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space22,
                    0,
                    AppSpacing.space22,
                    AppSpacing.space24,
                  ),
                  child: ProgressionCtaButton(
                    text: l10n.chooseThisDestination,
                    icon: Icons.check_circle_outline_rounded,
                    iconPosition: ProgressionCtaIconPosition.left,
                    enabled: _selectedCardIndex == null,
                    onPressed: _onChoose,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
