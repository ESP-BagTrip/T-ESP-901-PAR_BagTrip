import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Compact 30px-tall stepper for traveler breakdown rows (Plan trip).
class CompactTravelerStepper extends StatelessWidget {
  const CompactTravelerStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  static const double _size = 30;

  @override
  Widget build(BuildContext context) {
    final isAtMin = value <= min;
    final isAtMax = value >= max;

    return SizedBox(
      height: _size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CircleButton(
            icon: Icons.remove_rounded,
            isEnabled: !isAtMin,
            isPlus: false,
            onTap: isAtMin
                ? null
                : () {
                    AppHaptics.light();
                    onChanged(value - 1);
                  },
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontFamily: FontFamily.dMSerifDisplay,
                  fontSize: 16,
                  fontWeight: value > 0 ? FontWeight.w700 : FontWeight.w500,
                  color: value > 0 ? ColorName.primaryDark : ColorName.hint,
                ),
              ),
            ),
          ),
          _CircleButton(
            icon: Icons.add_rounded,
            isEnabled: !isAtMax,
            isPlus: true,
            onTap: isAtMax
                ? null
                : () {
                    AppHaptics.light();
                    onChanged(value + 1);
                  },
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.isEnabled,
    required this.isPlus,
    required this.onTap,
  });

  final IconData icon;
  final bool isEnabled;
  final bool isPlus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = ColorName.secondary;
    final borderColor = isPlus && isEnabled
        ? secondaryColor
        : ColorName.primarySoftLight;
    final iconColor = isPlus && isEnabled ? secondaryColor : ColorName.hint;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Opacity(
          opacity: isEnabled ? 1 : 0.35,
          child: Container(
            width: CompactTravelerStepper._size,
            height: CompactTravelerStepper._size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }
}
