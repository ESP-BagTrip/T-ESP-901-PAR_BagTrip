import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/profile/widgets/profile_detail_style.dart';
import 'package:bagtrip/profile/widgets/settings/settings_icon_badge.dart';
import 'package:bagtrip/profile/widgets/settings/settings_labeled_content.dart';
import 'package:flutter/material.dart';

/// Read-only or editable row: icon badge + label hierarchy + optional trailing.
class ProfileDetailLabeledRow extends StatelessWidget {
  const ProfileDetailLabeledRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.title,
    this.subtitle,
    this.boldTitle = true,
    this.titleColor,
    this.showLabel = true,
    this.cardSerifTypography = false,
    this.personalInfoTypography = false,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String title;
  final String? subtitle;
  final bool boldTitle;
  final Color? titleColor;
  final bool showLabel;
  final bool cardSerifTypography;
  final bool personalInfoTypography;
  final Widget? trailing;
  final VoidCallback? onTap;

  static const rowPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space16,
    vertical: AppSpacing.space12,
  );

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: rowPadding,
      child: Row(
        children: [
          SettingsIconBadge(icon: icon, iconColor: iconColor),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: SettingsLabeledContent(
              label: label,
              title: title,
              subtitle: subtitle,
              boldTitle: boldTitle,
              titleColor: titleColor,
              showLabel: showLabel,
              cardSerifTypography: cardSerifTypography,
              personalInfoTypography: personalInfoTypography,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

/// Trailing "Modify" action for editable profile detail rows.
class ProfileDetailModifyButton extends StatelessWidget {
  const ProfileDetailModifyButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
      ),
      child: Text(label, style: ProfileDetailStyle.modifyButtonStyle()),
    );
  }
}
