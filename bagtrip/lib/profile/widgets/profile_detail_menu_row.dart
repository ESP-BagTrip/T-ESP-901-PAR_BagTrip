import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/profile/widgets/profile_detail_labeled_row.dart';
import 'package:bagtrip/profile/widgets/profile_detail_style.dart';
import 'package:bagtrip/profile/widgets/settings/settings_icon_badge.dart';
import 'package:flutter/material.dart';

/// Tappable profile detail row with badge, title, and optional chevron.
class ProfileDetailMenuRow extends StatelessWidget {
  const ProfileDetailMenuRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.showChevron = true,
    this.titleColor,
    this.cardSerifTypography = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? titleColor;
  final bool cardSerifTypography;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final enabled = onTap != null;
    final titleStyle = cardSerifTypography
        ? ProfileDetailStyle.cardTitleStyle(
            brightness,
            color: titleColor,
            enabled: enabled,
          )
        : TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color:
                titleColor ??
                ProfileDetailStyle.titleColor(brightness, enabled: enabled),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: ProfileDetailLabeledRow.rowPadding,
          child: Row(
            children: [
              SettingsIconBadge(icon: icon, iconColor: iconColor),
              const SizedBox(width: AppSpacing.space12),
              Expanded(child: Text(title, style: titleStyle)),
              if (showChevron)
                Icon(
                  Icons.chevron_right,
                  color: ProfileDetailStyle.chevronColor(brightness),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
