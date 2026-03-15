import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/widgets/profile_section_card.dart';
import 'package:flutter/material.dart';

class PersonalInfoSection extends StatelessWidget {
  final String email;
  final String phone;
  final String address;

  const PersonalInfoSection({
    super.key,
    required this.email,
    required this.phone,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: ColorName.secondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                AppLocalizations.of(context)!.personalInfoTitle,
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
            icon: Icons.email_outlined,
            label: AppLocalizations.of(context)!.emailLabel,
            value: email,
          ),
          const SizedBox(height: AppSpacing.space16),
          _buildInfoRow(
            context: context,
            icon: Icons.phone_outlined,
            label: AppLocalizations.of(context)!.phoneLabel,
            value: phone,
          ),
          const SizedBox(height: AppSpacing.space16),
          _buildInfoRow(
            context: context,
            icon: Icons.location_on_outlined,
            label: AppLocalizations.of(context)!.addressLabel,
            value: address,
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ColorName.primaryTrueDark.withValues(alpha: 0.5),
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
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.comingSoon)),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
