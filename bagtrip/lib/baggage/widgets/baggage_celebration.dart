import 'dart:math';

import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BaggageCelebration extends StatefulWidget {
  const BaggageCelebration({super.key});

  @override
  State<BaggageCelebration> createState() => _BaggageCelebrationState();
}

class _BaggageCelebrationState extends State<BaggageCelebration>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _checkController.forward();
    _confettiController.forward();

    // Auto-dismiss after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Confetti particles
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(300, 400),
                    painter: _ConfettiPainter(
                      progress: _confettiController.value,
                    ),
                  );
                },
              ),

              // Central content
              AnimatedBuilder(
                animation: _checkAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _checkAnimation.value,
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    Text(
                      l10n.baggageAllPacked,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      l10n.baggageAllPackedSubtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final List<_Particle> _particles = _generateParticles();

  _ConfettiPainter({required this.progress});

  static List<_Particle> _generateParticles() {
    final random = Random(42);
    const colors = [
      AppColors.success,
      AppColors.primary,
      AppColors.warning,
      AppColors.primaryLight,
      AppColors.secondaryLight,
    ];
    return List.generate(30, (i) {
      return _Particle(
        x: random.nextDouble() * 300,
        velocityX: (random.nextDouble() - 0.5) * 100,
        velocityY: random.nextDouble() * 200 + 100,
        size: random.nextDouble() * 6 + 3,
        color: colors[random.nextInt(colors.length)],
        isCircle: random.nextBool(),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1 - progress).clamp(0.0, 1.0);
    for (final particle in _particles) {
      final paint = Paint()..color = particle.color.withValues(alpha: opacity);
      final x = particle.x + particle.velocityX * progress;
      final y = -20 + particle.velocityY * progress;

      if (particle.isCircle) {
        canvas.drawCircle(Offset(x, y), particle.size, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: particle.size * 1.5,
            height: particle.size,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double x;
  final double velocityX;
  final double velocityY;
  final double size;
  final Color color;
  final bool isCircle;

  const _Particle({
    required this.x,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.color,
    required this.isCircle,
  });
}
