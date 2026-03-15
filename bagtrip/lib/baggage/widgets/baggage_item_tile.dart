import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:flutter/material.dart';

class BaggageItemTile extends StatelessWidget {
  final BaggageItem item;
  final bool isReadOnly;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const BaggageItemTile({
    super.key,
    required this.item,
    this.isReadOnly = false,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPacked = item.isPacked;

    final tile = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      decoration: BoxDecoration(
        color: isPacked
            ? AppColors.surfaceLight.withValues(alpha: 0.6)
            : AppColors.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space4,
        ),
        leading: GestureDetector(
          onTap: isReadOnly ? null : onToggle,
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
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            decoration: isPacked ? TextDecoration.lineThrough : null,
            color: isPacked ? AppColors.hint : AppColors.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            if (item.category != null && item.category!.isNotEmpty)
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
                  item.category!,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                ),
              ),
            if (item.quantity != null && item.quantity! > 1) ...[
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
                  'x${item.quantity}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.hint),
                ),
              ),
            ],
          ],
        ),
        trailing: (!isReadOnly && onDelete != null)
            ? IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.hint,
                onPressed: onDelete,
              )
            : null,
      ),
    );

    if (isReadOnly) return tile;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onToggle();
        return false;
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: tile,
    );
  }
}
