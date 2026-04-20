import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// A single checkable item inside the Essentials / Baggage list.
///
/// Tapping the row invokes [onTap] which the caller uses to toggle packed.
/// [onEdit] / [onDelete] surface trailing icons when non-null (edit mode).
class PackItem extends StatelessWidget {
  const PackItem({
    super.key,
    required this.item,
    required this.reason,
    required this.checked,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final String item;
  final String reason;
  final bool checked;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.large16,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              checked
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: checked ? ColorName.secondary : AppColors.reviewUnchecked,
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      color: ColorName.primaryDark,
                    ),
                  ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      reason,
                      style: const TextStyle(
                        fontFamily: FontFamily.dMSans,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ColorName.hint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: ColorName.hint,
                ),
                visualDensity: VisualDensity.compact,
              ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: ColorName.hint,
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}
