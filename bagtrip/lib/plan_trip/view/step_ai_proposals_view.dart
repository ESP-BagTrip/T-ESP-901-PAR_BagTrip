import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
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
  int _activeCardIndex = 0;
  int? _expandedCardIndex;

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
  }

  @override
  void dispose() {
    _scaleAnim.dispose();
    _overlayAnim.dispose();
    _fadeOthersAnim.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  void _onSelectionComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      context.read<PlanTripBloc>().add(
        PlanTripEvent.swipeProposal(_activeCardIndex),
      );
    }
  }

  void _onChoose(int index) {
    // Double-tap guard
    if (_selectedCardIndex != null) return;

    AppHaptics.success();
    setState(() {
      _activeCardIndex = index;
      _selectedCardIndex = index;
    });
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

        return AnimatedBuilder(
          animation: _selectionController,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space24,
                    AppSpacing.space22,
                    AppSpacing.space24,
                    AppSpacing.space16,
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
                          fontFamily: FontFamily.dMSans,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorName.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      0,
                      AppSpacing.space16,
                      AppSpacing.space24,
                    ),
                    itemCount: state.aiSuggestions.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.space32),
                    itemBuilder: (context, suggestionIndex) {
                      final isSelected = _selectedCardIndex == suggestionIndex;
                      final isOther = _selectedCardIndex != null && !isSelected;
                      final overlayProgress = isSelected
                          ? _overlayAnim.value
                          : 0.0;
                      final opacity = isOther
                          ? 1.0 - 0.7 * _fadeOthersAnim.value
                          : 1.0;
                      final scale = isSelected
                          ? 1.0 + 0.03 * _scaleAnim.value
                          : 1.0;

                      return GestureDetector(
                        onTap: () => _onChoose(suggestionIndex),
                        child: Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: AiDestinationCard(
                              destination: state.aiSuggestions[suggestionIndex],
                              selectionProgress: overlayProgress,
                              isExpanded: _expandedCardIndex == suggestionIndex,
                              onToggleExpanded: () {
                                setState(() {
                                  _expandedCardIndex =
                                      _expandedCardIndex == suggestionIndex
                                      ? null
                                      : suggestionIndex;
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    },
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
