import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/primary_button.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/personalization/bloc/personalization_bloc.dart';
import 'package:bagtrip/personalization/widgets/budget_step_content.dart';
import 'package:bagtrip/personalization/widgets/companions_step_content.dart';
import 'package:bagtrip/personalization/widgets/personalization_progress_bar.dart';
import 'package:bagtrip/personalization/widgets/travel_style_step_content.dart';
import 'package:bagtrip/personalization/widgets/travel_types_step_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const int _kTotalSteps = 4;

class PersonalizationView extends StatelessWidget {
  const PersonalizationView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PersonalizationBloc, PersonalizationState>(
      listener: (context, state) {
        if (state is PersonalizationCompleted ||
            state is PersonalizationSkipped) {
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            context.go('/home');
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
    final isLastStep = state.step == _kTotalSteps;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryTrueDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            if (state.step > 1) {
              bloc.add(PersonalizationPreviousStep());
            } else {
              bloc.add(SkipPersonalization());
            }
          },
        ),
        title: PersonalizationProgressBar(
          current: state.step,
          total: _kTotalSteps,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.allEdgeInsetSpace24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stepTitle(l10n, state.step),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTrueDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      _stepSubtitle(l10n, state.step),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    _stepContent(context, state, bloc),
                  ],
                ),
              ),
            ),
            Padding(
              padding: AppSpacing.allEdgeInsetSpace24,
              child: Column(
                children: [
                  PrimaryButton(
                    label:
                        isLastStep
                            ? '${l10n.personalizationFinish} >'
                            : '${l10n.personalizationContinue} >',
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
                        style: const TextStyle(color: AppColors.textMutedLight),
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
        return l10n.personalizationStepTitleTravelTypes;
      case 2:
        return l10n.personalizationStepTitleTravelStyle;
      case 3:
        return l10n.personalizationStepTitleBudget;
      case 4:
        return l10n.personalizationStepTitleCompanions;
      default:
        return '';
    }
  }

  String _stepSubtitle(AppLocalizations l10n, int step) {
    switch (step) {
      case 1:
        return l10n.personalizationStepSubtitleTravelTypes;
      case 2:
        return l10n.personalizationStepSubtitleTravelStyle;
      case 3:
        return l10n.personalizationStepSubtitleBudget;
      case 4:
        return l10n.personalizationStepSubtitleCompanions;
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
      case 2:
        return TravelStyleStepContent(
          selectedId: state.travelStyle,
          onSelect: (id) => bloc.add(SetTravelStyle(id)),
        );
      case 3:
        return BudgetStepContent(
          selectedId: state.budget,
          onSelect: (id) => bloc.add(SetBudget(id)),
        );
      case 4:
        return CompanionsStepContent(
          selectedId: state.companions,
          onSelect: (id) => bloc.add(SetCompanions(id)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
