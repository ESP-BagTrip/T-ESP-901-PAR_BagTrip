import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/components/adaptive/adaptive_app_bar.dart';
import 'package:bagtrip/components/adaptive/adaptive_dialog.dart'
    show showAdaptiveAlertDialog;
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/profile/widgets/logout_button.dart';
import 'package:bagtrip/profile/widgets/profile_footer.dart';
import 'package:bagtrip/profile/widgets/profile_header_card.dart';
import 'package:bagtrip/profile/widgets/profile_section_card.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdaptiveAppBar.build(
        context: context,
        title: AppLocalizations.of(context)!.tabProfile,
      ),
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          if (state is UserProfileInitial || state is UserProfileLoading) {
            return const LoadingView();
          }

          if (state is UserProfileError) {
            return ErrorView(
              message: toUserFriendlyMessage(
                state.error,
                AppLocalizations.of(context)!,
              ),
              onRetry: () =>
                  context.read<UserProfileBloc>().add(LoadUserProfile()),
            );
          }

          if (state is UserProfileLoaded) {
            final l10n = AppLocalizations.of(context)!;

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeaderCard(
                  name: state.name.isNotEmpty ? state.name : state.email,
                  memberSince: DateFormat.yMMM(
                    Localizations.localeOf(context).languageCode,
                  ).format(state.memberSince),
                ),
                const SizedBox(height: AppSpacing.space16),
                _buildNavigationRow(
                  context,
                  icon: AdaptivePlatform.isIOS
                      ? CupertinoIcons.person
                      : Icons.person_outline,
                  title: l10n.personalInfoPageTitle,
                  onTap: () => const PersonalInfoRoute().go(context),
                ),
                const SizedBox(height: AppSpacing.space8),
                _buildNavigationRow(
                  context,
                  icon: AdaptivePlatform.isIOS
                      ? CupertinoIcons.airplane
                      : Icons.flight_outlined,
                  title: l10n.travelPreferencesTitle,
                  onTap: () =>
                      const PersonalizationRoute(from: 'profile').push(context),
                ),
                const SizedBox(height: AppSpacing.space8),
                _buildNavigationRow(
                  context,
                  icon: AdaptivePlatform.isIOS
                      ? CupertinoIcons.gear
                      : Icons.settings_outlined,
                  title: l10n.settingsTitle,
                  onTap: () => const SettingsRoute().go(context),
                ),
                const SizedBox(height: AppSpacing.space24),
                const LogoutButton(),
                const SizedBox(height: AppSpacing.space8),
                _buildDeleteAccountButton(context, l10n),
                const SizedBox(height: AppSpacing.space24),
                const ProfileFooter(),
              ],
            );

            if (AdaptivePlatform.isIOS) {
              return CupertinoScrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  child: content,
                ),
              );
            }

            return SingleChildScrollView(
              padding: AppSpacing.allEdgeInsetSpace24,
              child: content,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDeleteAccountButton(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => _confirmDeleteAccount(context, l10n),
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        child: Text(l10n.deleteAccountButton),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, AppLocalizations l10n) {
    final authBloc = context.read<AuthBloc>();
    showAdaptiveAlertDialog(
      context: context,
      title: l10n.deleteAccountConfirmTitle,
      content: l10n.deleteAccountConfirmMessage,
      confirmLabel: l10n.deleteAccountConfirmAction,
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      isDestructive: true,
      onConfirm: () {
        authBloc.add(DeleteAccountRequested());
      },
    );
  }

  Widget _buildNavigationRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ProfileSectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: ColorName.secondary, size: 20),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textDisabled,
            size: 20,
          ),
        ],
      ),
    );
  }
}
