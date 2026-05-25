import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/widgets/profile_detail_labeled_row.dart';
import 'package:bagtrip/profile/widgets/profile_detail_style.dart';
import 'package:bagtrip/profile/widgets/profile_menu_group_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PersonalInfoSection extends StatelessWidget {
  const PersonalInfoSection({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    this.onEditName,
    this.onEditPhone,
  });

  final String name;
  final String email;
  final String phone;
  final VoidCallback? onEditName;
  final VoidCallback? onEditPhone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSectionHeader(
          label: l10n.personalInfoTitle,
          icon: AdaptivePlatform.select(
            material: Icons.person_outline,
            cupertino: CupertinoIcons.person,
          ),
        ),
        ProfileMenuGroupCard(
          children: [
            ProfileDetailLabeledRow(
              icon: AdaptivePlatform.select(
                material: Icons.badge_outlined,
                cupertino: CupertinoIcons.person_crop_circle,
              ),
              iconColor: ProfileDetailStyle.iconAccentSecondary(),
              label: l10n.nameLabel,
              title: name,
              personalInfoTypography: true,
              trailing: onEditName != null
                  ? ProfileDetailModifyButton(
                      label: l10n.modifyButton,
                      onPressed: onEditName!,
                    )
                  : null,
            ),
            ProfileDetailLabeledRow(
              icon: AdaptivePlatform.select(
                material: Icons.email_outlined,
                cupertino: CupertinoIcons.mail,
              ),
              iconColor: ProfileDetailStyle.iconAccentSecondary(),
              label: l10n.emailLabel,
              title: email,
              personalInfoTypography: true,
            ),
            ProfileDetailLabeledRow(
              icon: AdaptivePlatform.select(
                material: Icons.phone_outlined,
                cupertino: CupertinoIcons.phone,
              ),
              iconColor: ProfileDetailStyle.iconAccentSecondary(),
              label: l10n.phoneLabel,
              title: phone,
              personalInfoTypography: true,
              trailing: onEditPhone != null
                  ? ProfileDetailModifyButton(
                      label: l10n.modifyButton,
                      onPressed: onEditPhone!,
                    )
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
