import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/premium_cta_button.dart';
import 'package:bagtrip/design/widgets/premium_step_indicator.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/personalization/bloc/personalization_bloc.dart';
import 'package:bagtrip/personalization/widgets/budget_step_content.dart';
import 'package:bagtrip/personalization/widgets/companions_step_content.dart';
import 'package:bagtrip/personalization/widgets/constraints_step_content.dart';
import 'package:bagtrip/personalization/widgets/travel_frequency_step_content.dart';
import 'package:bagtrip/personalization/widgets/travel_types_step_content.dart';
import 'package:bagtrip/personalization/widgets/welcome_step_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Welcome = 0, content steps 1–5 = companions, budget, interests, frequency, constraints.
const int _kContentSteps = 5;

double _responsiveHorizontalPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 360) return 16;
  if (width > 600) return 32;
  return 24;
}

class PersonalizationView extends StatelessWidget {
  const PersonalizationView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PersonalizationBloc, PersonalizationState>(
      listener: (context, state) {
        if (state is PersonalizationCompleted ||
            state is PersonalizationSkipped) {
          final fromCreateTripAi =
              GoRouterState.of(context).uri.queryParameters['from'] ==
              'createTripAi';
          if (fromCreateTripAi) {
            context.go('/trips/planifier/create-trip-ai');
          } else if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            context.go('/trips');
          }
        }
      },
      child: BlocBuilder<PersonalizationBloc, PersonalizationState>(
        builder: (context, state) {
          if (state is PersonalizationLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is! PersonalizationLoaded) {
            return const Scaffold(body: SizedBox.shrink());
          }
          return _buildLoaded(context, state);
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, PersonalizationLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<PersonalizationBloc>();

    if (state.step == 0) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: PersonalizationColors.backgroundGradient,
            ),
          ),
          child: SafeArea(
            child: WelcomeStepContent(
              totalSteps: _kContentSteps,
              onStart: () => bloc.add(PersonalizationNextStep()),
              onSkip: () => bloc.add(SkipPersonalization()),
            ),
          ),
        ),
      );
    }

    final isLastStep = state.step == _kContentSteps;

    return Scaffold(
      backgroundColor: PersonalizationColors.gradientEnd,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          color: PersonalizationColors.textPrimary,
          onPressed: () {
            if (state.step == 1 && Navigator.of(context).canPop()) {
              context.pop();
            } else {
              bloc.add(PersonalizationPreviousStep());
            }
          },
        ),
        title: PremiumStepIndicator(current: state.step, total: _kContentSteps),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  _responsiveHorizontalPadding(context),
                  8,
                  _responsiveHorizontalPadding(context),
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.space16),
                    Text(
                      _stepTitle(l10n, state.step),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: PersonalizationColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      _stepSubtitle(l10n, state.step),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: PersonalizationColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space32),
                    _stepContent(context, state, bloc),
                    const SizedBox(height: AppSpacing.space48),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                _responsiveHorizontalPadding(context),
                16,
                _responsiveHorizontalPadding(context),
                24,
              ),
              child: Column(
                children: [
                  PremiumCtaButton(
                    label:
                        isLastStep
                            ? l10n.personalizationFinish
                            : l10n.personalizationContinue,
                    onPressed: () {
                      if (isLastStep) {
                        bloc.add(SaveAndFinishPersonalization());
                      } else {
                        bloc.add(PersonalizationNextStep());
                      }
                    },
                  ),
                  if (state.step == 1) ...[
                    const SizedBox(height: AppSpacing.space16),
                    TextButton(
                      onPressed: () => bloc.add(SkipPersonalization()),
                      child: Text(
                        l10n.personalizationSkip,
                        style: const TextStyle(
                          color: PersonalizationColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(AppLocalizations l10n, int step) {
    switch (step) {
      case 1:
        return l10n.personalizationStepTitleHowYouTravel;
      case 2:
        return l10n.personalizationStepTitleBudgetQuestion;
      case 3:
        return l10n.personalizationStepTitleInterests;
      case 4:
        return l10n.personalizationStepTitleFrequency;
      case 5:
        return 'Contraintes';
      default:
        return '';
    }
  }

  String _stepSubtitle(AppLocalizations l10n, int step) {
    switch (step) {
      case 1:
        return l10n.personalizationStepSubtitleCompanions;
      case 2:
        return l10n.personalizationStepSubtitleBudget;
      case 3:
        return l10n.personalizationStepSubtitleInterests;
      case 4:
        return l10n.personalizationStepSubtitleFrequency;
      case 5:
        return 'Des restrictions ou contraintes pour votre voyage ?';
      default:
        return '';
    }
  }

  Widget _stepContent(
    BuildContext context,
    PersonalizationLoaded state,
    PersonalizationBloc bloc,
  ) {
    switch (state.step) {
      case 1:
        return CompanionsStepContent(
          selectedId: state.companions,
          onSelect: (id) => bloc.add(SetCompanions(id)),
        );
      case 2:
        return BudgetStepContent(
          selectedId: state.budget,
          onSelect: (id) => bloc.add(SetBudget(id)),
        );
      case 3:
        return TravelTypesStepContent(
          selectedIds: state.selectedTravelTypes,
          onToggle: (id) {
            final next = Set<String>.from(state.selectedTravelTypes);
            if (next.contains(id)) {
              next.remove(id);
            } else {
              next.add(id);
            }
            bloc.add(SetTravelTypes(next));
          },
        );
      case 4:
        return TravelFrequencyStepContent(
          selectedId: state.travelFrequency,
          onSelect: (id) => bloc.add(SetTravelFrequency(id)),
        );
      case 5:
        return ConstraintsStepContent(
          value: state.constraints,
          onChanged: (v) => bloc.add(SetConstraints(v.isEmpty ? null : v)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
