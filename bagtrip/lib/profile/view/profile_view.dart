import 'package:bagtrip/booking/bloc/booking_bloc.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:intl/intl.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/recent_booking.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/profile/widgets/experience_personalization_section.dart';
import 'package:bagtrip/profile/widgets/logout_button.dart';
import 'package:bagtrip/profile/widgets/personal_info_section.dart';
import 'package:bagtrip/profile/widgets/preferences_section.dart';
import 'package:bagtrip/profile/widgets/profile_footer.dart';
import 'package:bagtrip/profile/widgets/profile_header_card.dart';
import 'package:bagtrip/profile/widgets/recent_bookings_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
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
              PersonalInfoSection(
                email: state.email,
                phone: state.phone,
                address: state.address.isEmpty ? '—' : state.address,
              ),
              const SizedBox(height: AppSpacing.space16),
              const PreferencesSection(),
              const SizedBox(height: AppSpacing.space16),
              ExperiencePersonalizationSection(
                travelTypes: state.travelTypes,
                travelStyle: state.travelStyle,
                budget: state.budget,
                companions: state.companions,
              ),
              const SizedBox(height: AppSpacing.space16),
              BlocBuilder<BookingBloc, BookingState>(
                builder: (context, bookingState) {
                  final List<RecentBooking> bookings =
                      bookingState is BookingLoaded
                      ? bookingState.recentBookings
                      : [];
                  return RecentBookingsSection(recentBookings: bookings);
                },
              ),
              const SizedBox(height: AppSpacing.space24),
              const LogoutButton(),
              const SizedBox(height: AppSpacing.space24),
              const ProfileFooter(),
            ],
          );

          if (AdaptivePlatform.isIOS) {
            return CupertinoScrollbar(
              child: SingleChildScrollView(
                padding: AppSpacing.allEdgeInsetSpace24,
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
    );
  }
}
