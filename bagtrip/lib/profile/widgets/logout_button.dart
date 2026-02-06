import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final authService = AuthService();
            await authService.logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
          borderRadius: AppRadius.large16,
          child: Container(
            padding: AppSpacing.allEdgeInsetSpace16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: ColorName.error, size: 20),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  AppLocalizations.of(context)!.disconnect,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorName.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
