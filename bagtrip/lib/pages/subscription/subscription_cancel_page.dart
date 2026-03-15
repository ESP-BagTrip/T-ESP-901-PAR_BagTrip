import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/repositories/subscription_repository.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionCancelPage extends StatelessWidget {
  const SubscriptionCancelPage({super.key});

  Future<void> _retryCheckout(BuildContext context) async {
    final repo = getIt<SubscriptionRepository>();
    final result = await repo.getCheckoutUrl();

    if (!context.mounted) return;

    switch (result) {
      case Success(:final data):
        final uri = Uri.parse(data);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      case Failure():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorUnknown)),
        );
    }
  }

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
                    Icons.cancel_outlined,
                    size: 80,
                    color: ColorName.warning,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.subscriptionCancelTitle,
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
                    l10n.subscriptionCancelMessage,
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
                      onPressed: () => _retryCheckout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorName.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.retryButton),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => const ProfileRoute().go(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorName.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.subscriptionBackToProfile),
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
