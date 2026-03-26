import 'dart:async';

import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/step_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StepGenerationView extends StatefulWidget {
  const StepGenerationView({super.key});

  @override
  State<StepGenerationView> createState() => _StepGenerationViewState();
}

class _StepGenerationViewState extends State<StepGenerationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _timeoutTimer;
  bool _isTimedOut = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (mounted) setState(() => _isTimedOut = true);
    });
  }

  void _onRetry() {
    setState(() => _isTimedOut = false);
    _startTimeoutTimer();
    context.read<PlanTripBloc>().add(const PlanTripEvent.retryGeneration());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<PlanTripBloc, PlanTripState>(
      listenWhen: (prev, curr) =>
          prev.generationError != curr.generationError ||
          prev.generationProgress != curr.generationProgress,
      listener: (context, state) {
        if (state.generationError != null) {
          AppHaptics.error();
          _timeoutTimer?.cancel();
        }
        if (state.generationProgress >= 1.0) {
          AppHaptics.success();
          _timeoutTimer?.cancel();
        }
      },
      builder: (context, state) {
        final hasError = state.generationError != null || _isTimedOut;

        if (hasError) {
          return _buildErrorState(l10n, state);
        }
        return _buildGeneratingState(l10n, state);
      },
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, PlanTripState state) {
    final isTimeout = _isTimedOut && state.generationError == null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              isTimeout
                  ? l10n.generationTimeoutTitle
                  : l10n.generationErrorTitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: PersonalizationColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              isTimeout
                  ? l10n.generationTimeoutSubtitle
                  : l10n.generationErrorSubtitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                color: PersonalizationColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space32),
            _RetryButton(onPressed: _onRetry),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingState(AppLocalizations l10n, PlanTripState state) {
    final progressPercent = (state.generationProgress * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // Pulsing AI avatar
        Center(child: _PulsingAiAvatar(controller: _pulseController)),
        const SizedBox(height: AppSpacing.space24),

        // Message text with cross-fade
        AnimatedSwitcher(
          duration: AppAnimations.microInteraction,
          child: Text(
            state.generationMessage ?? '',
            key: ValueKey(state.generationMessage),
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 14,
              color: PersonalizationColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.space24),

        // Progress bar
        _ProgressBar(progress: state.generationProgress),
        const SizedBox(height: AppSpacing.space4),

        // Percentage label
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            l10n.generationProgressLabel(progressPercent),
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 12,
              color: PersonalizationColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space32),

        // Section header
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: ColorName.secondary,
            ),
            const SizedBox(width: AppSpacing.space8),
            Text(
              l10n.generationTitle,
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
        const SizedBox(height: AppSpacing.space16),

        // Generation checklist
        _GenerationChecklist(steps: state.generationSteps, l10n: l10n),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsing AI avatar — breathing halo effect
// ---------------------------------------------------------------------------

class _PulsingAiAvatar extends StatelessWidget {
  final AnimationController controller;

  const _PulsingAiAvatar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pulseValue = controller.value;
        final haloOpacity = 0.05 + 0.07 * pulseValue;

        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                PersonalizationColors.accentBlue.withValues(alpha: haloOpacity),
                PersonalizationColors.accentViolet.withValues(
                  alpha: haloOpacity * 0.5,
                ),
                Colors.transparent,
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: PersonalizationColors.accentGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: PersonalizationColors.accentBlue.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar with gradient fill
// ---------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return Container(
          height: 6,
          decoration: const BoxDecoration(
            color: ColorName.primarySoftLight,
            borderRadius: AppRadius.pill,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: AppAnimations.standardCurve,
              width: progress.clamp(0, 1) * maxWidth,
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: PersonalizationColors.accentGradient,
                ),
                borderRadius: AppRadius.pill,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Generation checklist — 5 rows with status icons
// ---------------------------------------------------------------------------

const _stepConfigs = [
  ('destinations', Icons.place_outlined),
  ('activities', Icons.local_activity_outlined),
  ('accommodations', Icons.hotel_outlined),
  ('baggage', Icons.luggage_outlined),
  ('budget', Icons.account_balance_wallet_outlined),
];

class _GenerationChecklist extends StatelessWidget {
  final Map<String, StepStatus> steps;
  final AppLocalizations l10n;

  const _GenerationChecklist({required this.steps, required this.l10n});

  String _labelForKey(String key) {
    return switch (key) {
      'destinations' => l10n.generationStepDestinations,
      'activities' => l10n.generationStepActivities,
      'accommodations' => l10n.generationStepAccommodations,
      'baggage' => l10n.generationStepBaggage,
      'budget' => l10n.generationStepBudget,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_stepConfigs.length, (i) {
        final (key, categoryIcon) = _stepConfigs[i];
        final status = steps[key] ?? StepStatus.pending;

        return StaggeredFadeIn(
          index: i,
          child: Padding(
            padding: AppSpacing.verticalSpace4,
            child: Row(
              children: [
                // Status icon with animated transition
                AnimatedSwitcher(
                  duration: AppAnimations.microInteraction,
                  child: _buildStatusIcon(status),
                ),
                const SizedBox(width: AppSpacing.space8),

                // Category icon
                Icon(categoryIcon, size: 20, color: _iconColor(status)),
                const SizedBox(width: AppSpacing.space8),

                // Label
                Expanded(
                  child: Text(
                    _labelForKey(key),
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      fontWeight: status == StepStatus.completed
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: _textColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatusIcon(StepStatus status) {
    return switch (status) {
      StepStatus.pending => const Icon(
        Icons.radio_button_unchecked,
        key: ValueKey('pending'),
        size: 20,
        color: ColorName.hint,
      ),
      StepStatus.inProgress => const SizedBox(
        key: ValueKey('inProgress'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            PersonalizationColors.accentBlue,
          ),
        ),
      ),
      StepStatus.completed => const Icon(
        Icons.check_circle_rounded,
        key: ValueKey('completed'),
        size: 20,
        color: AppColors.success,
      ),
      StepStatus.error => const Icon(
        Icons.error_outline_rounded,
        key: ValueKey('error'),
        size: 20,
        color: AppColors.error,
      ),
    };
  }

  Color _textColor(StepStatus status) {
    return switch (status) {
      StepStatus.completed => PersonalizationColors.textPrimary,
      StepStatus.inProgress => PersonalizationColors.accentBlue,
      StepStatus.pending => ColorName.hint,
      StepStatus.error => AppColors.error,
    };
  }

  Color _iconColor(StepStatus status) {
    return switch (status) {
      StepStatus.completed => PersonalizationColors.textPrimary,
      StepStatus.inProgress => PersonalizationColors.accentBlue,
      StepStatus.pending => ColorName.hint,
      StepStatus.error => AppColors.error,
    };
  }
}

// ---------------------------------------------------------------------------
// Retry button — gradient CTA (same pattern as _ChooseButton)
// ---------------------------------------------------------------------------

class _RetryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RetryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: PersonalizationColors.accentGradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: PersonalizationColors.accentBlue.withValues(alpha: 0.3),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  l10n.retryButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: FontFamily.b612,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
