import 'package:bagtrip/components/snack_bar_scope.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Soft email-verification reminder shown at the top of the profile.
///
/// Access is never blocked: the banner only appears while the current user's
/// `emailVerified` is `false` and collapses to nothing once verified. The
/// "Resend" action re-triggers the backend verification email and surfaces a
/// localized success/error toast.
class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  State<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _isSending = false;

  Future<void> _onResend() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    // Resolved lazily (not in a field initializer) so the banner can mount
    // in contexts where the AuthRepository isn't registered yet.
    final result = await getIt<AuthRepository>().resendVerification();
    if (!mounted) return;
    setState(() => _isSending = false);

    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case Success():
        SnackBarScope.of(context).show(
          context,
          message: l10n.emailVerificationSent,
          type: SnackBarType.success,
        );
      case Failure(:final error):
        SnackBarScope.of(context).show(
          context,
          message: toUserFriendlyMessage(error, l10n),
          type: SnackBarType.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = context.select<UserProfileBloc, bool>(
      (bloc) => switch (bloc.state) {
        UserProfileLoaded(:final emailVerified) => emailVerified,
        // Default to verified (hidden) until the profile resolves so the
        // banner never flashes on a not-yet-loaded state.
        _ => true,
      },
    );

    if (verified) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: AppSpacing.allEdgeInsetSpace16,
      margin: AppSpacing.onlyBottomSpace16,
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadius.large16,
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            color: AppColors.warningIcon,
            size: AppSize.iconSizeHeight24,
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Text(
              l10n.emailVerificationBannerText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.warningText,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          TextButton(
            onPressed: _isSending ? null : _onResend,
            style: TextButton.styleFrom(foregroundColor: AppColors.warningText),
            child: _isSending
                ? const SizedBox(
                    width: AppSize.boxSize16,
                    height: AppSize.boxSize16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.emailVerificationResend),
          ),
        ],
      ),
    );
  }
}
