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

/// Reactivate-subscription bottom sheet — symmetric to the cancel sheet
/// but with positive tone (primary CTA, no destructive action).
class ReactivateSubscriptionSheet extends StatelessWidget {
  const ReactivateSubscriptionSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<SubscriptionBloc>(),
        child: const ReactivateSubscriptionSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listenWhen: (prev, curr) =>
          prev.actionInFlight == SubscriptionAction.reactivating &&
          curr.actionInFlight == SubscriptionAction.idle,
      listener: (context, state) {
        if (state.error != null) return;
        Navigator.of(context).pop();
        HapticFeedback.lightImpact();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackBar.showSuccess(
            context,
            message: l10n.reactivateSheetSuccess,
          );
        });
      },
      builder: (context, state) {
        final loading = state.isReactivating;
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space24),
                  Text(
                    l10n.reactivateSheetTitle,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    l10n.reactivateSheetBody,
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
                    child: CupertinoButton.filled(
                      onPressed: loading
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              context.read<SubscriptionBloc>().add(
                                ReactivateSubscription(),
                              );
                            },
                      child: loading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : Text(l10n.reactivateSheetConfirm),
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
