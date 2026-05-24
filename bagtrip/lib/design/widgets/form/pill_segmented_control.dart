import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Segmented control (2–N options) with navy selected state and check icon.
class PillSegmentedControl<T> extends StatelessWidget {
  const PillSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.segments,
    this.compact = false,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<PillSegmentOption<T>> segments;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    assert(
      segments.length >= 2,
      'PillSegmentedControl needs at least 2 options',
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: ColorName.surfaceVariant,
        borderRadius: AppRadius.medium12,
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _SegmentButton<T>(
                option: segments[i],
                isSelected: segments[i].value == value,
                onTap: () => onChanged(segments[i].value),
                compact: compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PillSegmentOption<T> {
  const PillSegmentOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.compact,
  });

  final PillSegmentOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 11.0 : 13.0;
    final verticalPadding = compact ? AppSpacing.space8 : AppSpacing.space12;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium12,
        child: AnimatedContainer(
          duration: AppAnimationDurations.quick,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          decoration: BoxDecoration(
            color: isSelected ? ColorName.primaryTrueDark : Colors.transparent,
            borderRadius: AppRadius.medium12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 14, color: ColorName.surface),
                const SizedBox(width: 4),
              ] else if (option.icon != null) ...[
                Icon(option.icon, size: 14, color: ColorName.textMutedLight),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? ColorName.surface
                        : ColorName.textMutedLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
