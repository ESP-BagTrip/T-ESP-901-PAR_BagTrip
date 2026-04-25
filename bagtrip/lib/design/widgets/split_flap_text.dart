import 'dart:math' as math;

import 'package:bagtrip/design/app_colors.dart';
import 'package:flutter/material.dart';

enum SplitFlapMode { realistic, clean }

/// Vintage airport split-flap display text.
///
/// Animates each character through multiple flips before settling on [text].
class SplitFlapText extends StatefulWidget {
  const SplitFlapText({
    super.key,
    required this.text,
    this.duration = const Duration(milliseconds: 1600),
    this.textStyle = const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 1.1,
    ),
    this.backgroundColor = AppColors.primaryTrueDark,
    this.flapColor = AppColors.secondary,
    this.mode = SplitFlapMode.clean,
  });

  final String text;
  final Duration duration;
  final TextStyle textStyle;
  final Color backgroundColor;
  final Color flapColor;
  final SplitFlapMode mode;

  @override
  State<SplitFlapText> createState() => _SplitFlapTextState();
}

class _SplitFlapTextState extends State<SplitFlapText>
    with SingleTickerProviderStateMixin {
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  late final AnimationController _controller;
  late List<_CharPlan> _plans;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _plans = _buildPlans(widget.text, widget.mode);
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant SplitFlapText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.text != widget.text || oldWidget.mode != widget.mode) {
      _plans = _buildPlans(widget.text, widget.mode);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_CharPlan> _buildPlans(String text, SplitFlapMode mode) {
    final upper = text.toUpperCase();
    final plans = <_CharPlan>[];
    for (var i = 0; i < upper.length; i++) {
      final target = upper[i];
      if (!_alphabet.contains(target) || target == ' ') {
        plans.add(_CharPlan.space(target: text[i], delay: i * 0.045));
        continue;
      }

      final targetIndex = _alphabet.indexOf(target);
      late final int startIndex;
      late final int totalSteps;
      if (mode == SplitFlapMode.clean) {
        // Clean mode: only a few nearby characters before target.
        startIndex =
            (targetIndex - (3 + (i % 2)) + _alphabet.length) % _alphabet.length;
        totalSteps = 3 + (i % 2);
      } else {
        startIndex = (i * 7 + text.length * 3) % _alphabet.length;
        final minCycles = 1 + (i % 2);
        final delta =
            (targetIndex - startIndex + _alphabet.length) % _alphabet.length;
        totalSteps = (minCycles * _alphabet.length) + delta;
      }
      final jitter = (i % 4) * 0.01;
      plans.add(
        _CharPlan(
          target: target,
          delay: (i * 0.045) + jitter,
          startIndex: startIndex,
          totalSteps: totalSteps,
        ),
      );
    }
    return plans;
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.textStyle.fontSize ?? 32;
    final cellHeight = fontSize * 1.35;
    final cellWidth = (fontSize * 0.78).clamp(18, 56).toDouble();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final plan in _plans)
              _SplitFlapCell(
                progress: _progressFor(plan.delay),
                plan: plan,
                alphabet: _alphabet,
                textStyle: widget.textStyle,
                backgroundColor: widget.backgroundColor,
                flapColor: widget.flapColor,
                width: cellWidth,
                height: cellHeight,
              ),
          ],
        );
      },
    );
  }

  double _progressFor(double delay) {
    final p = (_controller.value - delay) / (1 - delay);
    return p.clamp(0.0, 1.0);
  }
}

class _SplitFlapCell extends StatelessWidget {
  const _SplitFlapCell({
    required this.progress,
    required this.plan,
    required this.alphabet,
    required this.textStyle,
    required this.backgroundColor,
    required this.flapColor,
    required this.width,
    required this.height,
  });

  final double progress;
  final _CharPlan plan;
  final String alphabet;
  final TextStyle textStyle;
  final Color backgroundColor;
  final Color flapColor;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (plan.isSpace) {
      return SizedBox(width: width * 0.6, height: height);
    }

    final total = plan.totalSteps;
    final rawStep = progress * total;
    final step = rawStep.floor().clamp(0, total);
    final stepProgress = rawStep - step;
    final current = _charAt(step);
    final next = _charAt((step + 1).clamp(0, total));
    final isSettled = progress >= 1;
    final staticChar = (!isSettled && stepProgress >= 0.5) ? next : current;

    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            _half(
              isSettled ? plan.target : staticChar,
              Alignment.bottomCenter,
              true,
            ),
            _half(
              isSettled ? plan.target : staticChar,
              Alignment.topCenter,
              false,
            ),
            if (!isSettled) _flippingTop(current, next, stepProgress),
            Positioned(
              top: height / 2 - 0.5,
              left: 0,
              right: 0,
              child: Container(height: 1, color: const Color(0x33000000)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _half(String char, Alignment align, bool bottom) {
    return Align(
      alignment: align,
      child: ClipRect(
        child: Align(
          alignment: align,
          heightFactor: 0.5,
          child: Container(
            color: flapColor,
            alignment: Alignment.center,
            child: Text(char, style: textStyle),
          ),
        ),
      ),
    );
  }

  Widget _flippingTop(String fromChar, String toChar, double t) {
    final firstHalf = t <= 0.5;
    final localT = firstHalf ? (t * 2) : ((t - 0.5) * 2);
    final angle = -localT * (math.pi / 2);
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0025)
      ..rotateX(angle);
    final shade = (localT * 0.35).clamp(0.0, 0.35);
    final flapChar = firstHalf ? fromChar : toChar;

    return Align(
      alignment: Alignment.topCenter,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 0.5,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: matrix,
            child: Stack(
              children: [
                Container(
                  color: flapColor.withValues(alpha: 0.8),
                  alignment: Alignment.center,
                  child: Text(flapChar, style: textStyle),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: shade),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _charAt(int step) {
    final idx = (plan.startIndex + step) % alphabet.length;
    return alphabet[idx];
  }
}

class _CharPlan {
  const _CharPlan({
    required this.target,
    required this.delay,
    required this.startIndex,
    required this.totalSteps,
  }) : isSpace = false;

  const _CharPlan.space({required this.target, required this.delay})
    : startIndex = 0,
      totalSteps = 0,
      isSpace = true;

  final String target;
  final double delay;
  final int startIndex;
  final int totalSteps;
  final bool isSpace;
}
