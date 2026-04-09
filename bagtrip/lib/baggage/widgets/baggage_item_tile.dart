import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:flutter/material.dart';

class BaggageItemTile extends StatefulWidget {
  final BaggageItem item;
  final bool isReadOnly;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BaggageItemTile({
    super.key,
    required this.item,
    this.isReadOnly = false,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<BaggageItemTile> createState() => _BaggageItemTileState();
}

class _BaggageItemTileState extends State<BaggageItemTile>
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
  void didUpdateWidget(covariant BaggageItemTile oldWidget) {
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
    final l10n = AppLocalizations.of(context)!;
    final isPacked = widget.item.isPacked;
    final theme = Theme.of(context);

    final tile = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
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
          onTap: widget.isReadOnly
              ? null
              : () {
                  AppHaptics.light();
                  widget.onToggle();
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
        subtitle: Row(
          children: [
            if (widget.item.category != null &&
                widget.item.category!.isNotEmpty)
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
            if (widget.item.quantity != null && widget.item.quantity! > 1) ...[
              const SizedBox(width: AppSpacing.space8),
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
          ],
        ),
      ),
    );

    if (widget.isReadOnly) return tile;

    final contextActions = <AdaptiveContextAction>[
      if (widget.onEdit != null)
        AdaptiveContextAction(
          label: l10n.baggageEditItemTitle,
          icon: Icons.edit_outlined,
          onPressed: widget.onEdit!,
        ),
      if (widget.onDelete != null)
        AdaptiveContextAction(
          label: l10n.baggageDeleteTitle,
          icon: Icons.delete_outline,
          onPressed: widget.onDelete!,
          isDestructive: true,
        ),
    ];

    return AdaptiveContextMenu(
      actions: contextActions,
      child: Dismissible(
        key: ValueKey(widget.item.id),
        direction: widget.onDelete != null
            ? DismissDirection.horizontal
            : DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            AppHaptics.light();
            widget.onToggle();
            return false;
          } else {
            AppHaptics.medium();
            widget.onDelete?.call();
            return false;
          }
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.space4),
          decoration: const BoxDecoration(
            color: AppColors.success,
            borderRadius: AppRadius.large16,
          ),
          alignment: Alignment.centerLeft,
          padding: AppSpacing.horizontalSpace16,
          child: Row(
            children: [
              const Icon(Icons.check, color: Colors.white),
              const SizedBox(width: AppSpacing.space8),
              Text(
                isPacked ? l10n.baggageUnpack : l10n.baggageSwipeToPack,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: widget.onDelete != null
            ? Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.space4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: AppRadius.large16,
                ),
                alignment: Alignment.centerRight,
                padding: AppSpacing.horizontalSpace16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.baggageSwipeToDelete,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    const Icon(Icons.delete_outline, color: Colors.white),
                  ],
                ),
              )
            : null,
        child: GestureDetector(onTap: widget.onEdit, child: tile),
      ),
    );
  }
}
