import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/repositories/subscription_repository.dart';
import 'package:bagtrip/subscription/bloc/subscription_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

/// Drives the native PaymentSheet in setup mode to update the card.
///
/// Replaces the legacy "Update payment method → Stripe Billing Portal"
/// jump. The user attaches a new card in the same sheet they paid in,
/// without ever leaving the app. On success we POST the freshly-attached
/// PaymentMethod id to `/payment-method/attach` so the next renewal
/// charges the new card.
///
/// This isn't a widget — there's no UI of our own to render. The Stripe
/// SDK *is* the UI. We just orchestrate it.
class UpdatePaymentMethodFlow {
  const UpdatePaymentMethodFlow._();

  /// Run the flow. Caller passes the [BuildContext] of the page that
  /// triggered it; this method handles loading state via a brief
  /// indicator dialog and pops it before/after the sheet.
  static Future<void> run(BuildContext context) async {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    final repo = getIt<SubscriptionRepository>();
    final subBloc = context.read<SubscriptionBloc>();

    // SetupIntent server-side, then init + present the sheet.
    final startResult = await repo.startPaymentMethodUpdate();
    if (!context.mounted) return;
    switch (startResult) {
      case Failure(:final error):
        AppSnackBar.showError(
          context,
          message: toUserFriendlyMessage(error, l10n),
        );
        return;
      case Success(:final data):
        try {
          await stripe.Stripe.instance.initPaymentSheet(
            paymentSheetParameters: stripe.SetupPaymentSheetParameters(
              merchantDisplayName: 'BagTrip',
              setupIntentClientSecret: data.setupIntentClientSecret,
              customerId: data.customer,
              customerEphemeralKeySecret: data.ephemeralKey,
              applePay: const stripe.PaymentSheetApplePay(
                merchantCountryCode: 'FR',
              ),
              googlePay: const stripe.PaymentSheetGooglePay(
                merchantCountryCode: 'FR',
                currencyCode: 'EUR',
              ),
              style: ThemeMode.system,
            ),
          );
          await stripe.Stripe.instance.presentPaymentSheet();
        } on stripe.StripeException catch (e) {
          if (e.error.code == stripe.FailureCode.Canceled) return;
          if (!context.mounted) return;
          AppSnackBar.showError(
            context,
            message: e.error.localizedMessage ?? l10n.errorUnknown,
          );
          return;
        } catch (_) {
          if (!context.mounted) return;
          AppSnackBar.showError(context, message: l10n.errorUnknown);
          return;
        }

        // SetupIntent succeeded → retrieve it to get the attached
        // PaymentMethod id, then ask the backend to wire it as default.
        // The flutter_stripe model declares `paymentMethodId` non-null
        // so a successful retrieve always yields one.
        final setupIntent = await stripe.Stripe.instance.retrieveSetupIntent(
          data.setupIntentClientSecret,
        );
        if (!context.mounted) return;

        final attachResult = await repo.attachPaymentMethod(
          setupIntent.paymentMethodId,
        );
        if (!context.mounted) return;
        switch (attachResult) {
          case Failure(:final error):
            AppSnackBar.showError(
              context,
              message: toUserFriendlyMessage(error, l10n),
            );
            return;
          case Success():
            HapticFeedback.lightImpact();
            // Re-fetch so the page chrome (last4, brand) updates.
            subBloc.add(LoadSubscription());
            AppSnackBar.showSuccess(
              context,
              message: l10n.updatePaymentMethodSuccess,
            );
        }
    }
  }
}
