import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/material.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: PersonalizationColors.gradientStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PersonalizationColors.backgroundGradient,
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
                    Icons.check_circle_outline,
                    size: 80,
                    color: ColorName.secondary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.paymentSuccessTitle,
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
                    l10n.paymentSuccessMessage,
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
                      onPressed: () => const HomeRoute().go(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorName.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.paymentBackToTrips),
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
