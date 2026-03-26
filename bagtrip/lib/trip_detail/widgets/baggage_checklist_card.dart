import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:flutter/material.dart';

class BaggageChecklistCard extends StatefulWidget {
  final BaggageItem item;
  final bool isOwner;
  final bool isCompleted;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const BaggageChecklistCard({
    super.key,
    required this.item,
    required this.isOwner,
    required this.isCompleted,
    this.onToggle,
    this.onDelete,
    this.onTap,
  });

  @override
  State<BaggageChecklistCard> createState() => _BaggageChecklistCardState();
}

class _BaggageChecklistCardState extends State<BaggageChecklistCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    if (widget.item.isPacked) {
      _bounceController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant BaggageChecklistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.isPacked != oldWidget.item.isPacked) {
      if (widget.item.isPacked) {
        _bounceController.forward(from: 0);
      } else {
        _bounceController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPacked = widget.item.isPacked;
    final theme = Theme.of(context);

    final tile = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isPacked
              ? AppColors.surfaceLight.withValues(alpha: 0.6)
              : AppColors.surface,
          borderRadius: AppRadius.large16,
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: ColorName.primary.withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 6,
              spreadRadius: -1,
            ),
            BoxShadow(
              color: ColorName.primary.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 4,
              spreadRadius: -1,
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space4,
          ),
          leading: GestureDetector(
            onTap: widget.isCompleted
                ? null
                : () {
                    AppHaptics.light();
                    widget.onToggle?.call();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPacked ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: isPacked ? AppColors.success : AppColors.hint,
                  width: 2,
                ),
              ),
              child: isPacked
                  ? AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _bounceAnimation.value,
                          child: child,
                        );
                      },
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          title: Text(
            widget.item.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: isPacked ? TextDecoration.lineThrough : null,
              color: isPacked ? AppColors.hint : AppColors.onSurface,
            ),
          ),
          subtitle: _buildSubtitle(theme),
        ),
      ),
    );

    if (!widget.isOwner || widget.isCompleted) return tile;

    return Dismissible(
      key: ValueKey(widget.item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        widget.onDelete?.call();
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: AppRadius.large16,
        ),
        alignment: Alignment.centerRight,
        padding: AppSpacing.horizontalSpace16,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: tile,
    );
  }

  Widget? _buildSubtitle(ThemeData theme) {
    final hasCategory =
        widget.item.category != null && widget.item.category!.isNotEmpty;
    final hasQuantity =
        widget.item.quantity != null && widget.item.quantity! > 1;

    if (!hasCategory && !hasQuantity) return null;

    return Row(
      children: [
        if (hasCategory)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space8,
              vertical: 2,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primarySoftLight,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              widget.item.category!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        if (hasCategory && hasQuantity)
          const SizedBox(width: AppSpacing.space8),
        if (hasQuantity)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space8,
              vertical: 2,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              'x${widget.item.quantity}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.hint,
              ),
            ),
          ),
      ],
    );
  }
}
