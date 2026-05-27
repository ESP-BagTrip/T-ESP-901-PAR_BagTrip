import 'dart:async';
import 'dart:math' as math;

import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
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
      duration: const Duration(milliseconds: 1400),
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
    _timeoutTimer = Timer(const Duration(seconds: 300), () {
      if (mounted) setState(() => _isTimedOut = true);
    });
  }

  void _onRetry() {
    setState(() => _isTimedOut = false);
    _startTimeoutTimer();
    final locale = Localizations.localeOf(context).languageCode;
    context.read<PlanTripBloc>().add(
      PlanTripEvent.retryGeneration(locale: locale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<PlanTripBloc, PlanTripState>(
      buildWhen: (prev, curr) =>
          prev.generationError != curr.generationError ||
          prev.generationProgress != curr.generationProgress ||
          prev.generationMessage != curr.generationMessage ||
          prev.currentStep != curr.currentStep,
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              isTimeout
                  ? l10n.generationTimeoutSubtitle
                  : l10n.generationErrorSubtitle,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.72),
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BlinkingAirplaneIcon(controller: _pulseController),
            const SizedBox(height: AppSpacing.space24),
            Text(
              l10n.generationHeroTitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space32),
            _ProgressBar(
              progress: state.generationProgress,
              onDarkBackground: true,
            ),
            const SizedBox(height: AppSpacing.space8),
            Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppAnimations.microInteraction,
                    child: Text(
                      state.generationMessage ?? '',
                      key: ValueKey(state.generationMessage),
                      style: TextStyle(
                        fontFamily: FontFamily.dMSans,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Text(
                  l10n.generationProgressLabel(progressPercent),
                  style: TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingAirplaneIcon extends StatelessWidget {
  const _BlinkingAirplaneIcon({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final blink = Curves.easeInOut.transform(controller.value);
        final opacity = 0.35 + (0.65 * blink);

        return Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: -math.pi / 4,
            child: Icon(
              Icons.flight_rounded,
              size: 56,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, this.onDarkBackground = false});

  final double progress;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final onDark = onDarkBackground;
    final clamped = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: clamped),
          duration: const Duration(milliseconds: 560),
          curve: Curves.easeInOutCubic,
          builder: (context, value, _) {
            return Container(
              height: onDark ? 4 : 3,
              decoration: BoxDecoration(
                color: onDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : ColorName.primarySoftLight.withValues(alpha: 0.9),
                borderRadius: AppRadius.pill,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: value * maxWidth,
                  height: onDark ? 4 : 3,
                  decoration: BoxDecoration(
                    color: onDark ? Colors.white : null,
                    gradient: onDark
                        ? null
                        : const LinearGradient(
                            colors: [ColorName.secondary, ColorName.primary],
                          ),
                    borderRadius: AppRadius.pill,
                    boxShadow: onDark
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.stepProgressGlow.withValues(
                                alpha: 0.42,
                              ),
                              blurRadius: 9,
                              spreadRadius: 0.4,
                            ),
                          ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
