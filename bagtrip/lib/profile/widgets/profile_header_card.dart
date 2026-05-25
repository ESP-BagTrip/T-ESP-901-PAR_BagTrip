import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.memberSince,
  });

  final String name;
  final String memberSince;

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim();
    final initials = _getInitials(displayName);
    const nameStyle = TextStyle(
      fontFamily: FontFamily.dMSerifDisplay,
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: AppColors.onPrimary,
      height: 1.15,
      letterSpacing: -0.5,
    );
    final memberSinceStyle = TextStyle(
      fontFamily: FontFamily.dMSans,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.onPrimary.withValues(alpha: 0.72),
      height: 1.4,
    );

    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: ColorName.secondary,
            borderRadius: AppRadius.large16,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: FontFamily.dMSans,
                color: AppColors.onPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: nameStyle),
              const SizedBox(height: AppSpacing.space4),
              Text(
                AppLocalizations.of(context)!.memberSinceText(memberSince),
                style: memberSinceStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
