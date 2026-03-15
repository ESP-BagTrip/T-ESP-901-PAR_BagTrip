import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class TripSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int itemCount;
  final List<String> previewItems;
  final String emptyLabel;
  final VoidCallback onTap;

  const TripSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.itemCount,
    required this.previewItems,
    required this.emptyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.large16,
          border: Border.all(color: ColorName.primarySoftLight),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: ColorName.primaryLight,
                    borderRadius: AppRadius.medium8,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: ColorName.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ColorName.primaryTrueDark,
                    ),
                  ),
                ),
                if (itemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: ColorName.primaryLight,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ColorName.primary,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: ColorName.primaryTrueDark.withValues(alpha: 0.4),
                ),
              ],
            ),

            // Preview items or empty state
            if (itemCount > 0 && previewItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...previewItems
                  .take(3)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(left: 54, right: 10),
                            decoration: const BoxDecoration(
                              color: ColorName.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontFamily: FontFamily.b612,
                                fontSize: 13,
                                color: ColorName.textMutedLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ] else if (itemCount == 0) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: Text(
                  emptyLabel,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: ColorName.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
