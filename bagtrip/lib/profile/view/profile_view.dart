import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/booking/bloc/booking_bloc.dart';
import 'package:bagtrip/booking/view/refund_sheet.dart';
import 'package:bagtrip/components/adaptive/adaptive_app_bar.dart';
import 'package:bagtrip/components/adaptive/adaptive_dialog.dart'
    show showAdaptiveAlertDialog;
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/recent_booking.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/profile/widgets/logout_button.dart';
import 'package:bagtrip/profile/widgets/profile_footer.dart';
import 'package:bagtrip/profile/widgets/profile_header_card.dart';
import 'package:bagtrip/profile/widgets/profile_section_card.dart';
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
                      ? CupertinoIcons.creditcard
                      : Icons.workspace_premium_outlined,
                  title: l10n.subscriptionPageTitle,
                  onTap: () => const SubscriptionSettingsRoute().go(context),
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
                _RecentBookingsBlock(
                  onLongPress: (booking) =>
                      _onBookingLongPress(context, booking),
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

  /// Long-press on a booking row.
  ///
  /// Refunds are only meaningful for **CAPTURED** bookings — for any other
  /// state we just no-op (an `INIT`/`AUTHORIZED` row hasn't been charged
  /// yet, a `REFUNDED` one is already done). Showing a toast on every
  /// long-press would be noise.
  void _onBookingLongPress(BuildContext context, RecentBooking booking) {
    if (booking.status.toUpperCase() != 'CAPTURED') {
      // Not refundable — surface a tiny info toast so a long-press isn't a
      // dead gesture, but keep it quiet.
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

  Widget _buildNavigationRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    // Internal helper; kept where it always was.
    return _NavigationRow(icon: icon, title: title, onTap: onTap);
  }
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
    // BookingBloc is provided at the app level. Guard against test contexts
    // that mount the profile view without it — keep the section quiet
    // rather than throwing a ProviderNotFoundException.
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
          return RecentBookingsSection(
            recentBookings: state.recentBookings,
            onLongPressBooking: widget.onLongPress,
          );
        }
        // Loading / error / initial — keep the slot quiet so the page
        // doesn't jump as the bloc resolves.
        return const SizedBox.shrink();
      },
    );
  }
}
