import 'dart:async';

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

class SubscriptionSuccessPage extends StatefulWidget {
  final String? sessionId;

  const SubscriptionSuccessPage({super.key, this.sessionId});

  @override
  State<SubscriptionSuccessPage> createState() =>
      _SubscriptionSuccessPageState();
}

class _SubscriptionSuccessPageState extends State<SubscriptionSuccessPage> {
  bool _loading = true;
  bool _isPremium = false;
  int _retryCount = 0;
  static const _maxRetries = 5;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final repo = getIt<SubscriptionRepository>();
    final result = await repo.getStatus();

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        final plan = data['plan'] as String?;
        if (plan != null && plan != 'FREE') {
          setState(() {
            _isPremium = true;
            _loading = false;
          });
        } else if (_retryCount < _maxRetries) {
          _retryCount++;
          _pollTimer = Timer(const Duration(seconds: 2), _checkStatus);
        } else {
          setState(() => _loading = false);
        }
      case Failure():
        if (_retryCount < _maxRetries) {
          _retryCount++;
          _pollTimer = Timer(const Duration(seconds: 2), _checkStatus);
        } else {
          setState(() => _loading = false);
        }
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
              child: _loading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator.adaptive(),
                        const SizedBox(height: 24),
                        Text(
                          l10n.subscriptionVerifying,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 16,
                            color: ColorName.primary,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPremium
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          size: 80,
                          color: _isPremium
                              ? ColorName.secondary
                              : ColorName.warning,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isPremium
                              ? l10n.subscriptionWelcomePremium
                              : l10n.subscriptionPending,
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
                          _isPremium
                              ? l10n.subscriptionSuccessMessage
                              : l10n.subscriptionPendingMessage,
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
                            onPressed: () => const ProfileRoute().go(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorName.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l10n.continueButton),
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
