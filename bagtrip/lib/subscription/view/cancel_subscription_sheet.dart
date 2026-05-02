import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/subscription/bloc/subscription_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Cancel-subscription bottom sheet.
///
/// Honest-by-design: no "Are you sure?" dialog stacked on top, no scary
/// red banner. The destructive primary action is full-width red, the
/// dismiss is a centred text link below — same pattern Apple uses for
/// Subscription Cancel in iOS Settings.
class CancelSubscriptionSheet extends StatelessWidget {
  const CancelSubscriptionSheet({super.key, this.expiresAt});
  final DateTime? expiresAt;

  static Future<void> show(BuildContext context, {DateTime? expiresAt}) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Capture the parent SubscriptionBloc so the sheet shares the same
      // instance — actions dispatched here update the page underneath.
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<SubscriptionBloc>(),
        child: CancelSubscriptionSheet(expiresAt: expiresAt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).languageCode,
    );
    final body = expiresAt == null
        ? l10n.cancelSheetBodyUndated
        : l10n.cancelSheetBodyDated(dateFormat.format(expiresAt!));

    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listenWhen: (prev, curr) =>
          prev.actionInFlight == SubscriptionAction.cancelling &&
          curr.actionInFlight == SubscriptionAction.idle,
      listener: (context, state) {
        if (state.error != null) return;
        Navigator.of(context).pop();
        HapticFeedback.lightImpact();
        // Wait one frame so the sheet pop animation isn't fighting the snackbar.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackBar.showSuccess(
            context,
            message: expiresAt != null
                ? l10n.cancelSheetSuccessDated(dateFormat.format(expiresAt!))
                : l10n.cancelSheetSuccessUndated,
          );
        });
      },
      builder: (context, state) {
        final loading = state.isCancelling;
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.cornerRadius28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space24,
                AppSpacing.space12,
                AppSpacing.space24,
                AppSpacing.space24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textDisabled.withValues(alpha: 0.3),
                        borderRadius: AppRadius.handleBar,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space24),
                  Text(
                    l10n.cancelSheetTitle,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textSecondaryOf(theme.brightness),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space32),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppColors.error,
                      onPressed: loading
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              context.read<SubscriptionBloc>().add(
                                CancelSubscription(),
                              );
                            },
                      child: loading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : Text(
                              l10n.cancelSheetConfirm,
                              style: const TextStyle(
                                fontFamily: FontFamily.b612,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  CupertinoButton(
                    onPressed: loading
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                    child: Text(
                      l10n.cancelSheetKeep,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 15,
                        color: AppColors.textSecondaryOf(theme.brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
