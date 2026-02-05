import 'package:bagtrip/design/tokens.dart';
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
        if (state is ProfileInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProfileLoaded) {
          return SingleChildScrollView(
            padding: AppSpacing.allEdgeInsetSpace24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeaderCard(
                  name: state.name,
                  memberSince: state.memberSince,
                ),
                const SizedBox(height: AppSpacing.space16),
                PersonalInfoSection(
                  email: state.email,
                  phone: state.phone,
                  address: state.address,
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
