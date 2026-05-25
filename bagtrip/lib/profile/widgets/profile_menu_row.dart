import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Tappable profile menu row with a colored icon container.
class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium12,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.medium12,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.profileMenuTitleOf(brightness),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: ColorName.hint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
