import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/models/inspiration_destination.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:flutter/material.dart';

class OnboardingHomeView extends StatelessWidget {
  final HomeNewUser state;

  const OnboardingHomeView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = state.displayName;

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  MediaQuery.paddingOf(context).left + AppSpacing.space24,
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Welcome icon
                StaggeredFadeIn(
                  index: 0,
                  baseDelay: const Duration(milliseconds: 80),
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [ColorName.primary, ColorName.secondary],
                      ),
                      borderRadius: AppRadius.large24,
                      boxShadow: [
                        BoxShadow(
                          color: ColorName.primary.withValues(alpha: 0.3),
                          offset: const Offset(0, 8),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      color: ColorName.surface,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space32),

                // Greeting
                StaggeredFadeIn(
                  index: 1,
                  baseDelay: const Duration(milliseconds: 80),
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    name.isNotEmpty
                        ? l10n.homeGreeting(name)
                        : l10n.homeWelcomeTitle,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),

                // Subtitle
                StaggeredFadeIn(
                  index: 2,
                  baseDelay: const Duration(milliseconds: 80),
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    l10n.homeWelcomeSubtitle,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.space48),

                // Primary CTA
                StaggeredFadeIn(
                  index: 3,
                  baseDelay: const Duration(milliseconds: 80),
                  duration: const Duration(milliseconds: 400),
                  child: _WelcomeCta(l10n: l10n),
                ),

                const SizedBox(height: AppSpacing.space32),

                // Inspiration section title
                StaggeredFadeIn(
                  index: 4,
                  baseDelay: const Duration(milliseconds: 80),
                  duration: const Duration(milliseconds: 400),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.onboardingInspirationTitle.toUpperCase(),
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),

                // Horizontal scroll — inspiration cards
                StaggeredFadeIn(
                  index: 5,
                  baseDelay: const Duration(milliseconds: 80),
                  duration: const Duration(milliseconds: 400),
                  child: SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: InspirationDestination.all.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.space12),
                      itemBuilder: (context, index) {
                        final dest = InspirationDestination.all[index];
                        return _InspirationCard(destination: dest);
                      },
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom padding
                SizedBox(
                  height: AdaptivePlatform.isIOS ? 100 : AppSpacing.space32,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeCta extends StatelessWidget {
  final AppLocalizations l10n;

  const _WelcomeCta({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => const PlanTripRoute().go(context),
        borderRadius: AppRadius.large24,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColorName.primary, ColorName.secondary],
            ),
            borderRadius: AppRadius.large24,
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.35),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: ColorName.surface,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.homeCreateFirstTrip,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ColorName.surface,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspirationCard extends StatelessWidget {
  final InspirationDestination destination;

  const _InspirationCard({required this.destination});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final location = LocationResult(
            name: destination.name,
            iataCode: destination.iataCode,
            city: destination.name,
            countryName: destination.country,
          );
          PlanTripRoute($extra: location).go(context);
        },
        borderRadius: AppRadius.large16,
        child: Container(
          width: 140,
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: destination.gradient,
            ),
            borderRadius: AppRadius.large16,
            boxShadow: [
              BoxShadow(
                color: destination.gradient.first.withValues(alpha: 0.25),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(destination.flag, style: const TextStyle(fontSize: 32)),
              const Spacer(),
              Text(
                destination.name,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ColorName.surface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                destination.country,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 12,
                  color: ColorName.surface.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
