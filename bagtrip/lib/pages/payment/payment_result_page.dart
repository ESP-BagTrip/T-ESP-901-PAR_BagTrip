import 'package:bagtrip/booking/bloc/booking_bloc.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 3DS deep-link return.
///
/// Stripe redirects back here after the bank's challenge with
/// `bagtrip://payment/result?intentId=…`. We dispatch
/// [ConfirmPaymentFromDeepLink] so the booking bloc validates the id
/// against the in-flight payment and either resumes capture or shows a
/// neutral "processed" state.
class PaymentResultPage extends StatefulWidget {
  final String? intentId;
  const PaymentResultPage({super.key, this.intentId});

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage> {
  @override
  void initState() {
    super.initState();
    final id = widget.intentId;
    if (id != null && id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<BookingBloc>().add(
          ConfirmPaymentFromDeepLink(intentId: id),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocConsumer<BookingBloc, BookingState>(
          listenWhen: (prev, curr) => prev != curr,
          listener: (context, state) {
            if (state is PaymentSuccess) {
              // Capture happened — flip to the success page so the result
              // page doesn't double up with the deep-link landing.
              PaymentSuccessRoute(intentId: state.intentId).go(context);
            }
          },
          builder: (context, state) {
            final isCapturing =
                state is PaymentAuthorizing || state is PaymentSheetReady;
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCapturing) ...[
                      const CupertinoActivityIndicator(),
                      const SizedBox(height: AppSpacing.space24),
                    ],
                    Text(
                      l10n.payment3dsReturnTitle,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    Text(
                      l10n.payment3dsReturnMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 14,
                        color: AppColors.textSecondaryOf(theme.brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space32),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: () => const HomeRoute().go(context),
                        child: Text(l10n.paymentBackToTrips),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
