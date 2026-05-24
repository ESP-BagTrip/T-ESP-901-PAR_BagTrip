import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentCancelPage extends StatelessWidget {
  const PaymentCancelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: PersonalizationColors.gradientStartOf(brightness),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PersonalizationColors.backgroundGradientOf(brightness),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.allEdgeInsetSpace24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    size: 80,
                    color: ColorName.warning,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.paymentCancelledTitle,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: ColorName.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.paymentCancelledMessage,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      color: ColorName.hint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorName.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.backButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
