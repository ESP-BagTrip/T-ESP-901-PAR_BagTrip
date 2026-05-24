import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class TravelerStepper extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const TravelerStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 10,
  });

  @override
  State<TravelerStepper> createState() => _TravelerStepperState();
}

class _TravelerStepperState extends State<TravelerStepper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 30),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(TravelerStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAtMin = widget.value <= widget.min;
    final isAtMax = widget.value >= widget.max;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Minus button
        GestureDetector(
          onTap: isAtMin
              ? null
              : () {
                  AppHaptics.light();
                  widget.onChanged(widget.value - 1);
                },
          child: Opacity(
            opacity: isAtMin ? 0.4 : 1.0,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: ColorName.surface,
                borderRadius: AppRadius.large16,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.remove_rounded,
                color: ColorName.onSurface,
              ),
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.space32),

        // Count display with bounce
        ScaleTransition(
          scale: _bounceAnimation,
          child: Text(
            '${widget.value}',
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: ColorName.primaryTrueDark,
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.space32),

        // Plus button
        GestureDetector(
          onTap: isAtMax
              ? null
              : () {
                  AppHaptics.light();
                  widget.onChanged(widget.value + 1);
                },
          child: Opacity(
            opacity: isAtMax ? 0.4 : 1.0,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: ColorName.surface,
                borderRadius: AppRadius.large16,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add_rounded, color: ColorName.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
