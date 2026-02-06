import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/bloc/profile_bloc.dart';
import 'package:bagtrip/profile/widgets/logout_button.dart';
import 'package:bagtrip/profile/widgets/personal_info_section.dart';
import 'package:bagtrip/profile/widgets/preferences_section.dart';
import 'package:bagtrip/profile/widgets/profile_footer.dart';
import 'package:bagtrip/profile/widgets/profile_header_card.dart';
import 'package:bagtrip/profile/widgets/recent_bookings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileInitial || state is ProfileUnauthenticated) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProfileLoadFailure) {
          return Center(
            child: Padding(
              padding: AppSpacing.allEdgeInsetSpace24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: ColorName.primaryTrueDark.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    state.message ??
                        AppLocalizations.of(context)!.profileLoadFailureMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColorName.primaryTrueDark.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space24),
                  FilledButton.icon(
                    onPressed:
                        () => context.read<ProfileBloc>().add(LoadProfile()),
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.retryButton),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProfileLoaded) {
          return SingleChildScrollView(
            padding: AppSpacing.allEdgeInsetSpace24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeaderCard(
                  name: state.name.isNotEmpty ? state.name : state.email,
                  memberSince: state.memberSince,
                ),
                const SizedBox(height: AppSpacing.space16),
                PersonalInfoSection(
                  email: state.email,
                  phone: state.phone,
                  address: state.address.isEmpty ? '—' : state.address,
                ),
                const SizedBox(height: AppSpacing.space16),
                PreferencesSection(
                  selectedTheme: state.selectedTheme,
                  selectedLanguage: state.selectedLanguage,
                ),
                const SizedBox(height: AppSpacing.space16),
                RecentBookingsSection(recentBookings: state.recentBookings),
                const SizedBox(height: AppSpacing.space24),
                const LogoutButton(),
                const SizedBox(height: AppSpacing.space24),
                const ProfileFooter(),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
