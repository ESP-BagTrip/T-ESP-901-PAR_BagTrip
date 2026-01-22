import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/primary_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppSpacing.allEdgeInsetSpace24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorName.secondary.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 60,
                  color: ColorName.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                AppLocalizations.of(context)!.myProfile,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                AppLocalizations.of(context)!.managePersonalInfo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorName.primaryTrueDark.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.space32),
              PrimaryButton(
                label: AppLocalizations.of(context)!.editProfile,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.space16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final authService = AuthService();
                    await authService.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: AppSpacing.allEdgeInsetSpace16,
                    side: const BorderSide(color: ColorName.error, width: 1.5),
                    foregroundColor: ColorName.error,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_outlined),
                      const SizedBox(width: AppSpacing.space8),
                      Text(AppLocalizations.of(context)!.disconnect),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
