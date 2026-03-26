import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

/// Multi-select chip for interests: pill shape, subtle highlight when selected.
class PremiumInterestChip extends StatefulWidget {
  const PremiumInterestChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<PremiumInterestChip> createState() => _PremiumInterestChipState();
}

class _PremiumInterestChipState extends State<PremiumInterestChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? PersonalizationColors.chipSelected
                : PersonalizationColors.chipUnselected,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.selected
                  ? PersonalizationColors.accentBlue.withValues(alpha: 0.6)
                  : PersonalizationColors.cardBorderUnselected,
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: widget.selected
                  ? PersonalizationColors.accentBlue
                  : PersonalizationColors.textPrimary,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
