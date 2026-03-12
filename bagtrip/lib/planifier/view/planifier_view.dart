import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/planifier/bloc/planifier_bloc.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PlanifierView extends StatelessWidget {
  const PlanifierView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlanifierBloc, PlanifierState>(
      builder: (context, state) {
        final inProgressCount =
            state is PlanifierLoaded ? state.inProgressCount : 0;
        final l10n = AppLocalizations.of(context)!;

        final horizontalPadding = EdgeInsets.only(
          left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
          right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
        );

        return Scaffold(
          backgroundColor: PersonalizationColors.gradientStart,
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + AppSpacing.space24,
              bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.space24,
            ),
            child: FutureBuilder<User?>(
              future: AuthService().getCurrentUser(),
              builder: (context, userSnapshot) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: horizontalPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, l10n, userSnapshot.data),
                          const SizedBox(height: AppSpacing.space24),
                          _buildSectionLabel(
                            context,
                            l10n.planifierSectionCreateTrip.toUpperCase(),
                          ),
                          const SizedBox(height: AppSpacing.space8),
                          _buildCreateTripSection(context, l10n),
                          const SizedBox(height: AppSpacing.space32),
                          _buildSectionLabel(
                            context,
                            l10n.planifierSectionMyTrips.toUpperCase(),
                          ),
                          const SizedBox(height: AppSpacing.space8),
                          _buildMyTripRow(
                            context,
                            l10n,
                            icon: Icons.calendar_today_rounded,
                            iconDecoration: const BoxDecoration(
                              color: ColorName.primaryLight,
                              borderRadius: AppRadius.medium8,
                            ),
                            iconColor: ColorName.primary,
                            title: l10n.planifierPlanningTitle,
                            description: l10n.planifierPlanningDescription,
                            trailing: l10n.planifierInProgressSuffix(
                              inProgressCount,
                            ),
                            onTap: () {},
                          ),
                          const SizedBox(height: AppSpacing.space8),
                          _buildMyTripRow(
                            context,
                            l10n,
                            icon: Icons.check_circle_rounded,
                            iconDecoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            iconColor: AppColors.surface,
                            title: l10n.planifierCompletedShort,
                            description: l10n.planifierCompletedDescriptionCard,
                            trailing: l10n.planifierCompletedSuffix(0),
                            onTap: () {},
                          ),
                          const SizedBox(height: AppSpacing.space32),
                          _buildSectionLabel(
                            context,
                            l10n.planifierSectionExploreDestinations
                                .toUpperCase(),
                          ),
                          const SizedBox(height: AppSpacing.space8),
                        ],
                      ),
                    ),
                    _buildExploreDestinationsSection(context, l10n),
                    const SizedBox(height: AppSpacing.space32),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, User? user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.planifierGreeting.toUpperCase(),
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorName.hint,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                l10n.planifierMainTitle,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primaryTrueDark,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                l10n.planifierSubtitle,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: ColorName.hint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: FontFamily.b612,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ColorName.primaryTrueDark,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCreateTripSection(BuildContext context, AppLocalizations l10n) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _CreateTripCardManual(
              title: l10n.planifierManualTitle,
              description: l10n.planifierManualDescriptionCard,
              onTap: () => context.push('/planifier/manual'),
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: _CreateTripCardAI(
              title: l10n.planifierAITitle,
              description: l10n.planifierAIDescriptionCard,
              newBadge: l10n.planifierNewBadge,
              onTap: () async {
                final user = await AuthService().getCurrentUser();
                final userId = user?.id ?? '';
                final hasSeen =
                    userId.isEmpty ||
                    await PersonalizationStorage().hasSeenPersonalizationPrompt(
                      userId,
                    );
                if (!context.mounted) return;
                if (hasSeen) {
                  context.push('/planifier/create-trip-ai');
                } else {
                  context.push('/personalization?from=createTripAi');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTripRow(
    BuildContext context,
    AppLocalizations l10n, {
    required IconData icon,
    required BoxDecoration iconDecoration,
    required Color iconColor,
    required String title,
    required String description,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large16,
        child: Container(
          padding: AppSpacing.allEdgeInsetSpace24,
          decoration: BoxDecoration(
            color: ColorName.surface,
            borderRadius: AppRadius.large16,
            border: Border.all(color: ColorName.primarySoftLight),
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.08),
                offset: const Offset(0, 4),
                blurRadius: 6,
                spreadRadius: -1,
              ),
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
                blurRadius: 4,
                spreadRadius: -1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: iconDecoration,
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ColorName.primaryTrueDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: ColorName.textMutedLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                trailing,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 13,
                  color: ColorName.hint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreDestinationsSection(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    const cardHeight = 150.0;

    return SizedBox(
      height: cardHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
        children: [
          _DestinationCard(
            city: l10n.destinationKyoto,
            country: l10n.countryJapan,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D6A6A), Color(0xFF1B4D4D)],
            ),
            icon: Icons.eco_rounded,
          ),
          const SizedBox(width: AppSpacing.space8),
          _DestinationCard(
            city: l10n.destinationSantorini,
            country: l10n.countryGreece,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColorName.primary, ColorName.primaryDark],
            ),
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(width: AppSpacing.space8),
          _DestinationCard(
            city: l10n.destinationMarrakech,
            country: l10n.countryMorocco,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFC45C26), Color(0xFF8B4513)],
            ),
            icon: Icons.landscape_rounded,
          ),
        ],
      ),
    );
  }
}

class _CreateTripCardManual extends StatelessWidget {
  const _CreateTripCardManual({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large16,
        child: Container(
          padding: AppSpacing.allEdgeInsetSpace24,
          decoration: BoxDecoration(
            color: ColorName.surface,
            borderRadius: AppRadius.large16,
            border: Border.all(color: ColorName.primarySoftLight),
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.08),
                offset: const Offset(0, 4),
                blurRadius: 6,
                spreadRadius: -1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: ColorName.primary,
                  borderRadius: AppRadius.medium8,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add,
                  color: ColorName.surface,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primaryTrueDark,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 13,
                  color: ColorName.textMutedLight,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateTripCardAI extends StatelessWidget {
  const _CreateTripCardAI({
    required this.title,
    required this.description,
    required this.newBadge,
    required this.onTap,
  });

  final String title;
  final String description;
  final String newBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large16,
        child: Container(
          padding: AppSpacing.allEdgeInsetSpace24,
          decoration: BoxDecoration(
            borderRadius: AppRadius.large16,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColorName.primary, ColorName.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.3),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ColorName.surface.withValues(alpha: 0.25),
                      borderRadius: AppRadius.medium8,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.auto_awesome,
                      color: ColorName.surface,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ColorName.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 13,
                      color: ColorName.surface.withValues(alpha: 0.9),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ColorName.surface.withValues(alpha: 0.3),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    newBadge,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ColorName.surface,
                      letterSpacing: 0.5,
                    ),
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

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.city,
    required this.country,
    required this.gradient,
    required this.icon,
  });

  final String city;
  final String country;
  final LinearGradient gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 150,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.large16,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ColorName.surface.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: ColorName.surface, size: 18),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  city,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ColorName.surface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  country,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    color: ColorName.surface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
