import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

/// Single-select premium card with glass style and scale animation.
class PremiumSelectCard extends StatefulWidget {
  const PremiumSelectCard({
    super.key,
    required this.label,
    this.icon,
    this.iconSize = 28,
    this.emoji,
    this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final double iconSize;
  final String? emoji;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<PremiumSelectCard> createState() => _PremiumSelectCardState();
}

class _PremiumSelectCardState extends State<PremiumSelectCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: AppSpacing.allEdgeInsetSpace24,
          decoration: BoxDecoration(
            color: widget.selected
                ? PersonalizationColors.cardSelectedTint
                : PersonalizationColors.cardUnselected,
            borderRadius: AppRadius.large20,
            border: Border.all(
              color: widget.selected
                  ? PersonalizationColors.cardBorderSelected
                  : PersonalizationColors.cardBorderUnselected,
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.emoji != null)
                Text(widget.emoji!, style: const TextStyle(fontSize: 32))
              else if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.selected
                      ? PersonalizationColors.accentBlue
                      : PersonalizationColors.textSecondary,
                ),
              if (widget.emoji != null || widget.icon != null)
                const SizedBox(width: AppSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: PersonalizationColors.textPrimary,
                      ),
                    ),
                    if (widget.description != null) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        widget.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PersonalizationColors.textSecondary,
                        ),
                      ),
                    ],
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
