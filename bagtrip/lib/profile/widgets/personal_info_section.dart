import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/widgets/profile_section_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PersonalInfoSection extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final VoidCallback? onEditName;
  final VoidCallback? onEditPhone;

  const PersonalInfoSection({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    this.onEditName,
    this.onEditPhone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AdaptivePlatform.select(
                  material: Icons.person_outline,
                  cupertino: CupertinoIcons.person,
                ),
                color: ColorName.secondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                l10n.personalInfoTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primaryTrueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          _buildInfoRow(
            context: context,
            icon: AdaptivePlatform.select(
              material: Icons.badge_outlined,
              cupertino: CupertinoIcons.person_crop_circle,
            ),
            label: l10n.nameLabel,
            value: name,
            onEdit: onEditName,
          ),
          const SizedBox(height: AppSpacing.space16),
          _buildInfoRow(
            context: context,
            icon: AdaptivePlatform.select(
              material: Icons.email_outlined,
              cupertino: CupertinoIcons.mail,
            ),
            label: l10n.emailLabel,
            value: email,
          ),
          const SizedBox(height: AppSpacing.space16),
          _buildInfoRow(
            context: context,
            icon: AdaptivePlatform.select(
              material: Icons.phone_outlined,
              cupertino: CupertinoIcons.phone,
            ),
            label: l10n.phoneLabel,
            value: phone,
            onEdit: onEditPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Row(
      children: [
        Icon(icon, color: ColorName.secondary.withValues(alpha: 0.7), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: ColorName.primaryTrueDark,
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
            ),
            child: Text(
              AppLocalizations.of(context)!.modifyButton,
              style: const TextStyle(
                fontSize: 14,
                color: ColorName.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
