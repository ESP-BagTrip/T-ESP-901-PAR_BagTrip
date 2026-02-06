import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
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

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
        boxShadow: [
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      padding: AppSpacing.allEdgeInsetSpace24,
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ColorName.primary, ColorName.secondary],
                  ),
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
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorName.secondary,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ColorName.primaryTrueDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  AppLocalizations.of(context)!.memberSinceText(memberSince),
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorName.primaryTrueDark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
