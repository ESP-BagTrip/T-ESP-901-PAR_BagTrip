import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/budget_chip_selector.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Single-card radio list for budget presets (Plan trip refont).
class BudgetPresetList extends StatelessWidget {
  const BudgetPresetList({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<BudgetOption> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.large16,
      child: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < options.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE8EAED),
                ),
              _BudgetPresetRow(
                option: options[i],
                isSelected: selectedIndex == i,
                onTap: () {
                  AppHaptics.light();
                  onSelected(i);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetPresetRow extends StatefulWidget {
  const _BudgetPresetRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final BudgetOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_BudgetPresetRow> createState() => _BudgetPresetRowState();
}

class _BudgetPresetRowState extends State<_BudgetPresetRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _fadeScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: AppAnimations.microInteraction,
    );
    _fadeScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutBack,
    );
    if (widget.isSelected) {
      _checkController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _BudgetPresetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _checkController.forward(from: 0);
      } else {
        _checkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.option;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.microInteraction,
          curve: AppAnimations.standardCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? ColorName.secondary.withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Text(o.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.label,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ColorName.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      o.range,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: ColorName.hint,
                      ),
                    ),
                  ],
                ),
              ),
              ScaleTransition(
                scale: _fadeScale,
                child: FadeTransition(
                  opacity: _fadeScale,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: widget.isSelected
                        ? Container(
                            decoration: const BoxDecoration(
                              color: ColorName.secondary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: ColorName.surface,
                            ),
                          )
                        : const SizedBox.shrink(),
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
