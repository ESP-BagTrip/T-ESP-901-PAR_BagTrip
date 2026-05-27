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

  /// Optional second line (e.g. exact date range under duration).
  final String? subtitle;

  const StepSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
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

  /// When true, collapsed state shows dates | travelers in two columns with a
  /// thin divider (expects at least two items: dates, then travelers).
  final bool enrichedSplitCollapsed;

  const StepHeader({
    super.key,
    required this.items,
    this.initiallyExpanded = false,
    this.onToggle,
    this.enrichedSplitCollapsed = false,
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: AppSpacing.allEdgeInsetSpace16,
        decoration: BoxDecoration(
          color: AppColors.surfaceGroupOf(brightness),
          borderRadius: AppRadius.large24,
          border: Border.all(color: AppColors.surfaceGroupBorderOf(brightness)),
          boxShadow: isDark
              ? null
              : [
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
          firstChild: _buildCollapsed(brightness),
          secondChild: _buildExpanded(brightness),
        ),
      ),
    );
  }

  Widget _buildCollapsed(Brightness brightness) {
    final mutedColor = AppColors.textSecondaryOf(brightness);
    if (widget.enrichedSplitCollapsed && widget.items.length >= 2) {
      return _buildEnrichedSplitCollapsed(
        widget.items[0],
        widget.items[1],
        brightness,
      );
    }
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              for (int i = 0; i < widget.items.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.space8),
                Icon(
                  widget.items[i].icon,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.space16),
                Flexible(
                  child: _collapsedValueText(widget.items[i], brightness),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Icon(Icons.keyboard_arrow_down, size: 18, color: mutedColor),
      ],
    );
  }

  Widget _buildEnrichedSplitCollapsed(
    StepSummaryItem dates,
    StepSummaryItem travelers,
    Brightness brightness,
  ) {
    final dividerColor = AppColors.surfaceGroupBorderOf(brightness);
    final mutedColor = AppColors.textSecondaryOf(brightness);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _enrichedSplitBlock(
            icon: dates.icon,
            primary: dates.value,
            secondary: dates.subtitle,
            brightness: brightness,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
          child: SizedBox(
            height: 44,
            child: VerticalDivider(width: 1, color: dividerColor),
          ),
        ),
        Expanded(
          child: _enrichedSplitBlock(
            icon: travelers.icon,
            primary: travelers.value,
            secondary: travelers.subtitle,
            brightness: brightness,
          ),
        ),
        const SizedBox(width: AppSpacing.space4),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _enrichedSplitBlock({
    required IconData icon,
    required String primary,
    required String? secondary,
    required Brightness brightness,
  }) {
    final titleColor = AppColors.profileMenuTitleOf(brightness);
    final mutedColor = AppColors.textSecondaryOf(brightness);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                primary,
                style: TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (secondary != null && secondary.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  secondary,
                  style: TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: mutedColor,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _collapsedValueText(StepSummaryItem item, Brightness brightness) {
    final titleColor = AppColors.profileMenuTitleOf(brightness);
    final mutedColor = AppColors.textSecondaryOf(brightness);
    if (item.subtitle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.value,
            style: TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
              height: 1.2,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            item.subtitle!,
            style: TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      );
    }
    return Text(
      item.value,
      style: TextStyle(
        fontFamily: FontFamily.b612,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: titleColor,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildExpanded(Brightness brightness) {
    final mutedColor = AppColors.textSecondaryOf(brightness);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space12),
          _buildExpandedRow(widget.items[i], brightness),
        ],
        const SizedBox(height: AppSpacing.space8),
        Icon(Icons.keyboard_arrow_up, size: 20, color: mutedColor),
      ],
    );
  }

  Widget _buildExpandedRow(StepSummaryItem item, Brightness brightness) {
    final titleColor = AppColors.profileMenuTitleOf(brightness);
    final mutedColor = AppColors.textSecondaryOf(brightness);
    final iconBg = brightness == Brightness.dark
        ? AppColors.surfaceGroupBorderOf(brightness)
        : ColorName.primaryLight;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
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
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                item.value,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  item.subtitle!,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: mutedColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
