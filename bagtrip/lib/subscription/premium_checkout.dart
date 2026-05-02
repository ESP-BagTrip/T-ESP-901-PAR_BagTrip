import 'dart:async';

import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/config/app_config.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/repositories/subscription_repository.dart';
import 'package:bagtrip/subscription/bloc/subscription_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

/// Run the deferred-IntentConfiguration PaymentSheet end to end.
///
/// Returns `true` when the user paid successfully (PaymentSheet returned
/// without throwing), `false` on cancel / error / network failure. The
/// caller decides what to do next — pop a sheet, navigate, both, or
/// neither — so the same flow drives the paywall popup *and* the
/// subscription page's FREE state without an intermediate popup hop.
///
/// Side-effects on success (fired before this returns):
///  * [OptimisticPremiumActivated] flips `user.plan` to PREMIUM locally
///    so the gate is lifted instantly.
///  * [ConfirmPremiumActivation] kicks the background reconciliation
///    against the server (500 ms → 2 s → 5 s).
///  * [LoadSubscription] re-fetches `/subscription/me` for the manage
///    screen.
///  * "Premium activé" snackbar on the parent ScaffoldMessenger.
///
/// On error (anything other than user cancel) a red snackbar surfaces
/// the localized message and the function returns false. Pure cancel
/// is silent — the user just dismissed the sheet, not an event worth a
/// toast.
class PremiumCheckout {
  const PremiumCheckout._();

  static Future<bool> run(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // Capture everything we need *before* any async work so post-payment
    // side-effects can fire even if the caller's State disposes (e.g.
    // when the paywall sheet pops).
    final messenger = ScaffoldMessenger.of(context);
    final authBloc = context.read<AuthBloc>();
    final subscriptionBloc = context.read<SubscriptionBloc>();
    final repository = getIt<SubscriptionRepository>();

    try {
      // 1. Bootstrap — no Stripe write, just `{customer, ephemeralKey,
      //    amount, currency}` to render the sheet.
      debugPrint('[checkout] starting bootstrap');
      final startResult = await repository.start();
      switch (startResult) {
        case Failure(:final error):
          debugPrint('[checkout] /start failed: $error');
          _showError(messenger, toUserFriendlyMessage(error, l10n));
          return false;
        case Success(:final data):
          debugPrint(
            '[checkout] /start ok — customer=${data.customer}, '
            '${data.amount} ${data.currency}',
          );

          // 2. Init the PaymentSheet in deferred IntentConfiguration mode.
          //    The Subscription will be created on demand inside the
          //    confirmHandler — no orphan `incomplete` subs.
          await stripe.Stripe.instance.initPaymentSheet(
            paymentSheetParameters: stripe.SetupPaymentSheetParameters(
              merchantDisplayName: 'BagTrip',
              customerId: data.customer,
              customerEphemeralKeySecret: data.ephemeralKey,
              intentConfiguration: stripe.IntentConfiguration(
                mode: stripe.IntentMode.paymentMode(
                  currencyCode: data.currency.toUpperCase(),
                  amount: data.amount,
                  setupFutureUsage: stripe.IntentFutureUsage.OffSession,
                ),
                paymentMethodTypes: const ['card'],
                confirmHandler: (paymentMethod, _) {
                  // Stripe SDK calls this when the user taps Pay. Async
                  // body kicked off via `unawaited`; the SDK is told via
                  // `intentCreationCallback` when the server returns.
                  unawaited(
                    _handleConfirm(
                      repository: repository,
                      paymentMethodId: paymentMethod.id,
                      l10n: l10n,
                    ),
                  );
                },
              ),
              // Apple Pay only renders when a merchant id is configured
              // — both the global `Stripe.merchantIdentifier` AND the
              // Xcode capability. Passing the params with a null merchant
              // id throws an assertion in the SDK, so we gate on the
              // dart-define flag here.
              applePay: AppConfig.appleMerchantIdentifier.isEmpty
                  ? null
                  : const stripe.PaymentSheetApplePay(
                      merchantCountryCode: 'FR',
                    ),
              googlePay: const stripe.PaymentSheetGooglePay(
                merchantCountryCode: 'FR',
                currencyCode: 'EUR',
                testEnv: kDebugMode,
              ),
              style: ThemeMode.system,
            ),
          );

          // 3. Present. Throws on cancel/error, returns silently on
          //    success — by then Stripe has confirmed the payment
          //    (3DS included).
          await stripe.Stripe.instance.presentPaymentSheet();

          // 4. Optimistic update — paint the user PREMIUM locally now
          //    on BOTH blocs, let the webhook reconcile in the background.
          //    AuthBloc drives feature gates (paywall opens, premium
          //    badge); SubscriptionBloc drives the manage-subscription
          //    screen body. If we only flip auth and naively
          //    LoadSubscription, the manage screen flickers back to
          //    FREE the moment `/subscription/me` answers (webhook
          //    races the response).
          authBloc
            ..add(OptimisticPremiumActivated())
            ..add(ConfirmPremiumActivation());
          subscriptionBloc
            ..add(OptimisticSubscriptionActivated())
            ..add(ConfirmSubscriptionActivation());

          // 5. Subtle confirmation. The caller is responsible for
          //    closing any sheet / popping back to the originating
          //    screen.
          messenger
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.premiumActivated),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(milliseconds: 1800),
              ),
            );
          return true;
      }
    } on stripe.StripeException catch (e, st) {
      // Cancel is a non-event — no toast, just bail silently.
      if (e.error.code == stripe.FailureCode.Canceled) {
        debugPrint('[checkout] user cancelled the sheet');
        return false;
      }
      debugPrint(
        '[checkout] StripeException: code=${e.error.code} '
        'message=${e.error.message} declineCode=${e.error.declineCode}\n$st',
      );
      _showError(
        messenger,
        e.error.localizedMessage ?? e.error.message ?? l10n.errorUnknown,
      );
      return false;
    } catch (e, st) {
      debugPrint('[checkout] unexpected error: $e\n$st');
      _showError(messenger, '${l10n.errorUnknown}: $e');
      return false;
    }
  }

  /// PaymentSheet `confirmHandler` body — async-safe wrapper.
  ///
  /// Stripe's typedef for `ConfirmHandler` is `void Function`, but the
  /// work is async (server round-trip), so we kick it off via
  /// [unawaited] and call back via `Stripe.instance.intentCreationCallback`
  /// when ready. Errors are reported to Stripe so the sheet can render
  /// the right message in-line.
  static Future<void> _handleConfirm({
    required SubscriptionRepository repository,
    required String paymentMethodId,
    required AppLocalizations l10n,
  }) async {
    final result = await repository.confirmSubscription(paymentMethodId);
    switch (result) {
      case Success(:final data):
        await stripe.Stripe.instance.intentCreationCallback(
          stripe.IntentCreationCallbackParams(clientSecret: data),
        );
      case Failure(:final error):
        // Hand the error back to the SDK so the sheet can render the
        // right message in-line. `FailureCode.Failed` is the catch-all
        // enum value the SDK expects when the server-side confirm call
        // can't deliver a usable client_secret.
        await stripe.Stripe.instance.intentCreationCallback(
          stripe.IntentCreationCallbackParams(
            error: stripe.StripeException(
              error: stripe.LocalizedErrorMessage(
                code: stripe.FailureCode.Failed,
                localizedMessage: toUserFriendlyMessage(error, l10n),
                message: error.message,
              ),
            ),
          ),
        );
    }
  }

  static void _showError(ScaffoldMessengerState messenger, String message) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
