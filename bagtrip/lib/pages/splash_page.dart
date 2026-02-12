import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/assets.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/backend_health.dart';
import 'package:bagtrip/service/onboarding_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Minimum display duration for the splash screen so it remains visible.
const Duration _kMinSplashDuration = Duration(milliseconds: 1500);

/// Startup loading screen: waits for backend to be ready, validates token via API,
/// then redirects to /home if logged in, else to /onboarding (if not seen) or /login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _waitBackendThenCheckAuthAndNavigate(),
    );
  }

  Future<void> _waitBackendThenCheckAuthAndNavigate() async {
    final startedAt = DateTime.now();

    final backendReady = await waitForBackendReady();
    if (!backendReady) {
      if (!mounted) return;
      _showConnectionErrorDialog();
      return;
    }

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _kMinSplashDuration) {
      await Future<void>.delayed(_kMinSplashDuration - elapsed);
    }

    if (!mounted) return;

    final authService = AuthService();
    final user = await authService.getCurrentUser();

    if (!mounted) return;

    if (user != null) {
      context.go('/home');
    } else {
      await authService.logout();
      if (!mounted) return;
      final hasSeen = await OnboardingStorage().hasSeenOnboarding();
      if (!mounted) return;
      if (hasSeen) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    }
  }

  void _showConnectionErrorDialog() {
    final l10n = AppLocalizations.of(context)!;
    final useCupertino =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    final Future<bool?> dialogFuture =
        useCupertino
            ? showCupertinoDialog<bool>(
              context: context,
              builder:
                  (context) => CupertinoAlertDialog(
                    title: Text(l10n.splashConnectionErrorTitle),
                    content: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(l10n.splashConnectionErrorMessage),
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.retryButton),
                      ),
                    ],
                  ),
            )
            : showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => AlertDialog(
                    title: Text(l10n.splashConnectionErrorTitle),
                    content: Text(l10n.splashConnectionErrorMessage),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.retryButton),
                      ),
                    ],
                  ),
            );

    dialogFuture.then((retry) {
      if (retry == true && mounted) {
        _waitBackendThenCheckAuthAndNavigate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientMid,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: AppSpacing.allEdgeInsetSpace24,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Assets.images.appIcon.svg(width: 100, height: 100),
              ),
              const SizedBox(height: AppSpacing.space24),
              Text(
                'BagTrip',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTrueDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                l10n.splashLoading,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
