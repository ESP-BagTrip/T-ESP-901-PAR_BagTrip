import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// A single summary item displayed inside [StepHeader].
class StepSummaryItem {
  final IconData icon;
  final String label;
  final String value;

  const StepSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// Resume compact of wizard steps completed, expandable.
///
/// Collapsed: a single row of icon + value pairs.
/// Expanded: a column where each row shows icon box, label and value.
class StepHeader extends StatefulWidget {
  final List<StepSummaryItem> items;
  final bool initiallyExpanded;
  final VoidCallback? onToggle;

  const StepHeader({
    super.key,
    required this.items,
    this.initiallyExpanded = false,
    this.onToggle,
  });

  @override
  State<StepHeader> createState() => _StepHeaderState();
}

class _StepHeaderState extends State<StepHeader> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: AppSpacing.allEdgeInsetSpace16,
        decoration: BoxDecoration(
          color: ColorName.surface,
          borderRadius: AppRadius.large16,
          border: Border.all(color: ColorName.primarySoftLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: AnimatedCrossFade(
          duration: AppAnimations.cardTransition,
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _buildCollapsed(),
          secondChild: _buildExpanded(),
        ),
      ),
    );
  }

  Widget _buildCollapsed() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              for (int i = 0; i < widget.items.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.space8),
                Icon(widget.items[i].icon, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space4),
                Flexible(
                  child: Text(
                    widget.items[i].value,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ColorName.primaryTrueDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.hint),
      ],
    );
  }

  Widget _buildExpanded() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space12),
          _buildExpandedRow(widget.items[i]),
        ],
        const SizedBox(height: AppSpacing.space8),
        const Icon(Icons.keyboard_arrow_up, size: 20, color: AppColors.hint),
      ],
    );
  }

  Widget _buildExpandedRow(StepSummaryItem item) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: ColorName.primaryLight,
            borderRadius: AppRadius.medium8,
          ),
          alignment: Alignment.center,
          child: Icon(item.icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ColorName.hint,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                item.value,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primaryTrueDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
