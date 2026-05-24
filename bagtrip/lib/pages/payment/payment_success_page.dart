import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Calm payment success — no oversized checkmark, just typography +
/// a single subtle accent dot. Haptic notification fires once on entry
/// for the celebratory beat.
class PaymentSuccessPage extends StatefulWidget {
  final String? intentId;
  const PaymentSuccessPage({super.key, this.intentId});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use mediumImpact rather than success notification — the latter is
      // too loud, and we already have visual feedback.
      HapticFeedback.mediumImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space32),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: AppSpacing.space32),
              Text(
                l10n.paymentSuccessConfirmed,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                l10n.paymentSuccessSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondaryOf(theme.brightness),
                ),
              ),
              if (widget.intentId != null) ...[
                const SizedBox(height: AppSpacing.space24),
                Text(
                  'Ref · ${widget.intentId!.substring(0, widget.intentId!.length.clamp(0, 8))}',
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    color: AppColors.textDisabled,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () => const HomeRoute().go(context),
                  child: Text(l10n.paymentBackToTrips),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
            ],
          ),
        ),
      ),
    );
  }
}
