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
  Timer? _titleDotsTimer;
  bool _isTimedOut = false;
  int _titleDotCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _titleDotsTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (!mounted) return;
      setState(() => _titleDotCount = (_titleDotCount + 1) % 4);
    });
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _titleDotsTimer?.cancel();
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space22,
        AppSpacing.space22,
        AppSpacing.space22,
        40,
      ),
      children: [
        const SizedBox(height: AppSpacing.space8),
        Center(child: _AIAuraOrb(controller: _pulseController)),
        const SizedBox(height: AppSpacing.space16),

        AnimatedSwitcher(
          duration: AppAnimations.microInteraction,
          child: Text(
            state.generationMessage ?? '',
            key: ValueKey(state.generationMessage),
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: PersonalizationColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.space24),

        _ProgressBar(progress: state.generationProgress),
        const SizedBox(height: AppSpacing.space4),

        Align(
          alignment: Alignment.centerRight,
          child: Text(
            l10n.generationProgressLabel(progressPercent),
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 11,
              fontWeight: FontWeight.w300,
              color: PersonalizationColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space32),

        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: ColorName.secondary,
            ),
            const SizedBox(width: AppSpacing.space8),
            Text(
              l10n.generationTitle,
              style: const TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ColorName.secondary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space16),

        _GenerationChecklist(
          steps: state.generationSteps,
          l10n: l10n,
          activeMessage: state.generationMessage,
        ),
      ],
    );
  }
}

class _AIAuraOrb extends StatelessWidget {
  final AnimationController controller;

  const _AIAuraOrb({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final bob = math.sin(t * 2 * math.pi) * 4;

        return Transform.translate(
          offset: Offset(0, bob),
          child: SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (int i = 0; i < 3; i++)
                  _OrbRing(
                    progress: (t + i * 0.28) % 1,
                    color: ColorName.secondary,
                    baseSize: 88,
                  ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [ColorName.primary, ColorName.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorName.secondary.withValues(alpha: 0.26),
                        blurRadius: 24,
                        spreadRadius: 1.2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.45),
                      radius: 0.9,
                      colors: [
                        ColorName.surface.withValues(alpha: 0.35),
                        ColorName.surface.withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 1],
                    ),
                  ),
                ),
                CustomPaint(size: const Size(24, 24), painter: _StarPainter()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrbRing extends StatelessWidget {
  const _OrbRing({
    required this.progress,
    required this.color,
    required this.baseSize,
  });

  final double progress;
  final Color color;
  final double baseSize;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOut.transform(progress);
    final size = baseSize + 58 * eased;
    final opacity = (1 - eased) * 0.2;

    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.75), width: 1.1),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();
    const spikes = 4;
    const outerRadius = 7.0;
    const innerRadius = 2.8;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round
      ..color = ColorName.surface.withValues(alpha: 0.98);

    var rotation = -math.pi / 2;
    final step = math.pi / spikes;
    path.moveTo(
      center.dx + math.cos(rotation) * outerRadius,
      center.dy + math.sin(rotation) * outerRadius,
    );
    for (var i = 0; i < spikes; i++) {
      rotation += step;
      path.lineTo(
        center.dx + math.cos(rotation) * innerRadius,
        center.dy + math.sin(rotation) * innerRadius,
      );
      rotation += step;
      path.lineTo(
        center.dx + math.cos(rotation) * outerRadius,
        center.dy + math.sin(rotation) * outerRadius,
      );
    }
    path.close();
    canvas.drawPath(path, paint);

    final sparkPaint = Paint()
      ..color = ColorName.surface.withValues(alpha: 0.9);
    canvas.drawCircle(
      Offset(center.dx + 6.3, center.dy - 6.1),
      1.7,
      sparkPaint,
    );
    canvas.drawCircle(
      Offset(center.dx - 6.0, center.dy + 5.8),
      1.2,
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double _displayedProgress = 0;

  @override
  void initState() {
    super.initState();
    _displayedProgress = widget.progress.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(covariant _ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.progress - widget.progress).abs() > 0.001) {
      setState(() => _displayedProgress = widget.progress.clamp(0.0, 1.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: _displayedProgress),
          duration: const Duration(milliseconds: 560),
          curve: Curves.easeInOutCubic,
          builder: (context, value, _) {
            return Container(
              height: 3,
              decoration: BoxDecoration(
                color: ColorName.primarySoftLight.withValues(alpha: 0.9),
                borderRadius: AppRadius.pill,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: value * maxWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ColorName.secondary, ColorName.primary],
                    ),
                    borderRadius: AppRadius.pill,
                    boxShadow: [
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

const _stepConfigs = [
  ('destinations', Icons.place_outlined),
  ('activities', Icons.local_activity_outlined),
  ('accommodations', Icons.home_outlined),
  ('baggage', Icons.luggage_outlined),
  ('budget', Icons.savings_outlined),
];

class _GenerationChecklist extends StatelessWidget {
  const _GenerationChecklist({
    required this.steps,
    required this.l10n,
    required this.activeMessage,
  });

  final Map<String, StepStatus> steps;
  final AppLocalizations l10n;
  final String? activeMessage;

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

  String _subtitleForKey(String key, StepStatus status) {
    return switch (status) {
      StepStatus.pending => 'En attente de traitement',
      StepStatus.inProgress => activeMessage ?? 'Traitement en cours...',
      StepStatus.completed => switch (key) {
        'destinations' => 'Destination validée',
        'activities' => 'Activités planifiées',
        'accommodations' => 'Hébergements sélectionnés',
        'baggage' => 'Bagages optimisés',
        'budget' => 'Budget finalisé',
        _ => 'Terminé',
      },
      StepStatus.error => l10n.generationErrorSubtitle,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.large24,
        border: Border.all(color: ColorName.primarySoftLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.large24,
        child: Column(
          children: List.generate(_stepConfigs.length, (index) {
            final (key, categoryIcon) = _stepConfigs[index];
            final status = steps[key] ?? StepStatus.pending;
            final isLast = index == _stepConfigs.length - 1;

            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: AppAnimations.standardCurve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space16,
                    vertical: AppSpacing.space12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Center(
                          child: _StepStatusIndicator(status: status),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space8),
                      Icon(categoryIcon, size: 18, color: _iconColor(status)),
                      const SizedBox(width: AppSpacing.space8),
                      Expanded(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: AppAnimations.standardCurve,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _labelForKey(key),
                                style: TextStyle(
                                  fontFamily: FontFamily.dMSans,
                                  fontSize: 15.5,
                                  fontWeight: status == StepStatus.completed
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: _textColor(status),
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Text(
                                  _subtitleForKey(key, status),
                                  key: ValueKey('$key-$status-$activeMessage'),
                                  style: TextStyle(
                                    fontFamily: FontFamily.dMSans,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: _subtitleColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                    ),
                    color: ColorName.primarySoftLight.withValues(alpha: 0.9),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Color _textColor(StepStatus status) {
    return switch (status) {
      StepStatus.completed => PersonalizationColors.textPrimary,
      StepStatus.inProgress => AppColors.stepInProgress,
      StepStatus.pending => ColorName.hint,
      StepStatus.error => AppColors.error,
    };
  }

  Color _subtitleColor(StepStatus status) {
    return switch (status) {
      StepStatus.completed => AppColors.stepCompletedSubtitle,
      StepStatus.inProgress => AppColors.stepInProgressSubtitle,
      StepStatus.pending => PersonalizationColors.textTertiary,
      StepStatus.error => AppColors.error,
    };
  }

  Color _iconColor(StepStatus status) {
    return switch (status) {
      StepStatus.completed => PersonalizationColors.textSecondary,
      StepStatus.inProgress => AppColors.stepInProgress,
      StepStatus.pending => ColorName.hint,
      StepStatus.error => AppColors.error,
    };
  }
}

class _StepStatusIndicator extends StatelessWidget {
  const _StepStatusIndicator({required this.status});

  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppAnimations.microInteraction,
      child: switch (status) {
        StepStatus.pending => Container(
          key: const ValueKey('pending'),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ColorName.hint.withValues(alpha: 0.3)),
          ),
        ),
        StepStatus.inProgress => const _ThinTealSpinner(
          key: ValueKey('inProgress'),
          size: 20,
        ),
        StepStatus.completed => Container(
          key: const ValueKey('completed'),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.stepSuccessBg,
            border: Border.all(color: AppColors.stepSuccessBorder, width: 1.2),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: AppColors.stepSuccessBorder,
          ),
        ),
        StepStatus.error => const Icon(
          Icons.error_outline_rounded,
          key: ValueKey('error'),
          size: 20,
          color: AppColors.error,
        ),
      },
    );
  }
}

class _ThinTealSpinner extends StatefulWidget {
  const _ThinTealSpinner({super.key, required this.size});

  final double size;

  @override
  State<_ThinTealSpinner> createState() => _ThinTealSpinnerState();
}

class _ThinTealSpinnerState extends State<_ThinTealSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _SpinnerPainter(),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.stepInProgress.withValues(alpha: 0.2);
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8
      ..color = AppColors.stepInProgress;

    canvas.drawArc(rect.deflate(1), 0, math.pi * 2, false, bgPaint);
    canvas.drawArc(
      rect.deflate(1),
      -math.pi / 2,
      math.pi * 1.25,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
