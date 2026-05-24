import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/booking/bloc/booking_bloc.dart';
import 'package:bagtrip/booking/view/refund_sheet.dart';
import 'package:bagtrip/components/adaptive/adaptive_dialog.dart'
    show showAdaptiveAlertDialog;
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/recent_booking.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/profile/widgets/email_verification_banner.dart';
import 'package:bagtrip/profile/widgets/profile_delete_account_tile.dart';
import 'package:bagtrip/profile/widgets/profile_header_card.dart';
import 'package:bagtrip/profile/widgets/profile_menu_group_card.dart';
import 'package:bagtrip/profile/widgets/profile_menu_row.dart';
import 'package:bagtrip/profile/widgets/profile_section_label.dart';
import 'package:bagtrip/profile/widgets/profile_two_zone_layout.dart';
import 'package:bagtrip/profile/widgets/recent_bookings_section.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state) {
        if (state is UserProfileInitial || state is UserProfileLoading) {
          return const Scaffold(body: LoadingView());
        }

        if (state is UserProfileError) {
          return Scaffold(
            body: ErrorView(
              message: toUserFriendlyMessage(
                state.error,
                AppLocalizations.of(context)!,
              ),
              onRetry: () =>
                  context.read<UserProfileBloc>().add(LoadUserProfile()),
            ),
          );
        }

        if (state is UserProfileLoaded) {
          return _ProfileLoadedContent(state: state);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _ProfileLoadedContent extends StatelessWidget {
  const _ProfileLoadedContent({required this.state});

  final UserProfileLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final memberSince = DateFormat.yMMM(
      Localizations.localeOf(context).languageCode,
    ).format(state.memberSince);

    return Scaffold(
      body: ProfileTwoZoneLayout(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EmailVerificationBanner(),
            ProfileHeaderCard(
              name: state.name.isNotEmpty ? state.name : state.email,
              memberSince: memberSince,
            ),
          ],
        ),
        children: [
          ProfileSectionLabel(label: l10n.profileSectionMyAccount),
          ProfileMenuGroupCard(
            children: [
              ProfileMenuRow(
                icon: AdaptivePlatform.isIOS
                    ? CupertinoIcons.person
                    : Icons.person_outline,
                title: l10n.personalInfoPageTitle,
                iconColor: ColorName.secondary,
                onTap: () => const PersonalInfoRoute().go(context),
              ),
              ProfileMenuRow(
                icon: AdaptivePlatform.isIOS
                    ? CupertinoIcons.airplane
                    : Icons.flight_outlined,
                title: l10n.travelPreferencesTitle,
                iconColor: ColorName.secondary,
                onTap: () =>
                    const PersonalizationRoute(from: 'profile').push(context),
              ),
              ProfileMenuRow(
                icon: AdaptivePlatform.isIOS
                    ? CupertinoIcons.creditcard
                    : Icons.workspace_premium_outlined,
                title: l10n.subscriptionPageTitle,
                iconColor: ColorName.warning,
                onTap: () => const SubscriptionSettingsRoute().go(context),
              ),
              ProfileMenuRow(
                icon: AdaptivePlatform.isIOS
                    ? CupertinoIcons.gear
                    : Icons.settings_outlined,
                title: l10n.settingsTitle,
                iconColor: ColorName.hint,
                onTap: () => const SettingsRoute().go(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space24),
          _RecentBookingsBlock(
            onLongPress: (booking) => _onBookingLongPress(context, booking),
          ),
          const SizedBox(height: AppSpacing.space24),
          ProfileSectionLabel(label: l10n.profileSectionSession),
          ProfileMenuGroupCard(
            children: [
              ProfileMenuRow(
                icon: AdaptivePlatform.isIOS
                    ? CupertinoIcons.square_arrow_right
                    : Icons.logout,
                title: l10n.disconnect,
                iconColor: ColorName.hint,
                onTap: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                  const LoginRoute().go(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          ProfileDeleteAccountTile(
            onTap: () => _confirmDeleteAccount(context, l10n),
          ),
        ],
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

  void _onBookingLongPress(BuildContext context, RecentBooking booking) {
    if (booking.status.toUpperCase() != 'CAPTURED') {
      AppSnackBar.showInfo(
        context,
        message: AppLocalizations.of(context)!.refundUnavailableMessage,
      );
      return;
    }
    final amountCents = (booking.priceTotal * 100).round();
    RefundSheet.show(
      context,
      intentId: booking.id,
      capturedAmountCents: amountCents,
      currency: booking.currency,
    );
  }
}

/// Profile-side rendering of recent bookings.
///
/// Owns the [BookingBloc] subscription so the section reflects live state
/// without forcing the parent profile view to know anything about bookings.
/// Hides itself when there's nothing to show — no point in flashing an
/// empty card during the first profile render.
class _RecentBookingsBlock extends StatefulWidget {
  const _RecentBookingsBlock({required this.onLongPress});
  final void Function(RecentBooking booking) onLongPress;

  @override
  State<_RecentBookingsBlock> createState() => _RecentBookingsBlockState();
}

class _RecentBookingsBlockState extends State<_RecentBookingsBlock> {
  @override
  void initState() {
    super.initState();
    final bloc = _readBookingBlocOrNull(context);
    if (bloc != null && bloc.state is BookingInitial) {
      bloc.add(LoadBookings());
    }
  }

  BookingBloc? _readBookingBlocOrNull(BuildContext context) {
    try {
      return context.read<BookingBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_readBookingBlocOrNull(context) == null) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<BookingBloc, BookingState>(
      buildWhen: (prev, curr) =>
          curr is BookingLoaded ||
          curr is BookingError ||
          curr is BookingLoading,
      builder: (context, state) {
        if (state is BookingLoaded) {
          if (state.recentBookings.isEmpty) {
            return const SizedBox.shrink();
          }
          final l10n = AppLocalizations.of(context)!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileSectionLabel(label: l10n.tripsMyTrips.toUpperCase()),
              RecentBookingsSection(
                recentBookings: state.recentBookings,
                onLongPressBooking: widget.onLongPress,
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
