import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/planifier/bloc/planifier_bloc.dart';
import 'package:bagtrip/planifier/widgets/planifier_card.dart';
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

        return Scaffold(
          backgroundColor: PersonalizationColors.gradientStart,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.allEdgeInsetSpace24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.planifierSectionCreateTrip,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTrueDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  PlanifierCard(
                    icon: _buildIconContainer(
                      context,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.medium8,
                      ),
                      icon: Icons.add,
                    ),
                    title: l10n.planifierManualTitle,
                    description: l10n.planifierManualDesc,
                    onTap: () => context.push('/planifier/manual'),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  PlanifierCard(
                    icon: _buildIconContainer(
                      context,
                      decoration: const BoxDecoration(
                        borderRadius: AppRadius.medium8,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                      ),
                      icon: Icons.auto_awesome,
                    ),
                    title: l10n.planifierAITitle,
                    description: l10n.planifierAIDesc,
                    onTap: () async {
                      final user = await AuthService().getCurrentUser();
                      final userId = user?.id ?? '';
                      final hasSeen =
                          userId.isEmpty ||
                          await PersonalizationStorage()
                              .hasSeenPersonalizationPrompt(userId);
                      if (!context.mounted) return;
                      if (hasSeen) {
                        context.push('/planifier/create-trip-ai');
                      } else {
                        context.push('/personalization?from=createTripAi');
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.space32),
                  Text(
                    l10n.planifierSectionMyTrips,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTrueDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  PlanifierCard(
                    icon: _buildIconContainer(
                      context,
                      decoration: const BoxDecoration(),
                      icon: Icons.description_outlined,
                      iconColor: AppColors.warning,
                    ),
                    title: l10n.planifierInProgressTitle,
                    description: l10n.planifierInProgressCount(inProgressCount),
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  PlanifierCard(
                    icon: _buildIconContainer(
                      context,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      icon: Icons.check,
                    ),
                    title: l10n.planifierCompletedTitle,
                    description: l10n.planifierCompletedDesc,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconContainer(
    BuildContext context, {
    required BoxDecoration decoration,
    required IconData icon,
    Color? iconColor,
    double size = 48,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: iconColor ?? AppColors.surface,
        size: size * 0.5,
      ),
    );
  }
}
