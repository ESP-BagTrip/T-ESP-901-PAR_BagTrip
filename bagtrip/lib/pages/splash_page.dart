import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/assets.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/service/backend_health.dart';
import 'package:bagtrip/service/onboarding_storage.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bagtrip/navigation/route_definitions.dart';

/// Minimum display duration for the splash screen so it remains visible.
const Duration _kMinSplashDuration = Duration(milliseconds: 1500);

/// Startup loading screen: waits for backend to be ready, validates token via API,
/// then redirects to /trips if logged in, else to /onboarding (if not seen) or /login.
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

    await waitForBackendReady();

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _kMinSplashDuration) {
      await Future<void>.delayed(_kMinSplashDuration - elapsed);
    }

    if (!mounted) return;

    final authRepository = getIt<AuthRepository>();
    final userResult = await authRepository.getCurrentUser();
    final user = userResult.dataOrNull;

    if (!mounted) return;

    if (user != null) {
      if (!user.isProfileCompleted) {
        final hasSeen = await getIt<PersonalizationStorage>()
            .hasSeenPersonalizationPrompt(user.id);
        if (!hasSeen) {
          if (!mounted) return;
          const PersonalizationRoute().go(context);
          return;
        }
      }
      if (!mounted) return;
      const HomeRoute().go(context);
    } else {
      await authRepository.logout();
      if (!mounted) return;
      final hasSeen = await getIt<OnboardingStorage>().hasSeenOnboarding();
      if (!mounted) return;
      if (hasSeen) {
        const LoginRoute().go(context);
      } else {
        const OnboardingRoute().go(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PersonalizationColors.backgroundGradientOf(
              Theme.of(context).brightness,
            ),
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
              SizedBox(
                width: 32,
                height: 32,
                child: AdaptivePlatform.isIOS
                    ? const CupertinoActivityIndicator(radius: 14)
                    : const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
