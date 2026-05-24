import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String memberSince;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.memberSince,
  });

  String _getInitials(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '';
  }

  String _displayName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final displayName = _displayName(name);

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
                color: AppColors.surface,
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
              Text(
                displayName,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSerifDisplay,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: ColorName.surface,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                AppLocalizations.of(context)!.memberSinceText(memberSince),
                style: TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 14,
                  color: ColorName.surface.withValues(alpha: 0.72),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
