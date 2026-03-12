import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

/// Premium full-width CTA with gradient, large padding, soft shadow.
class PremiumCtaButton extends StatefulWidget {
  const PremiumCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<PremiumCtaButton> createState() => _PremiumCtaButtonState();
}

class _PremiumCtaButtonState extends State<PremiumCtaButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, maxHeight: 48),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: AppSpacing.space24,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: PersonalizationColors.accentGradient,
              ),
              borderRadius: AppRadius.large20,
              boxShadow: [
                BoxShadow(
                  color: PersonalizationColors.accentBlue.withValues(
                    alpha: 0.35,
                  ),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                ),
              ],
            ),
            child:
                widget.isLoading
                    ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                    : Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
