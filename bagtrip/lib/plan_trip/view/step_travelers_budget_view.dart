import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/budget_chip_selector.dart';
import 'package:bagtrip/design/widgets/budget_preset_list.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/helpers/budget_estimation.dart';
import 'package:bagtrip/plan_trip/helpers/traveler_breakdown_format.dart';
import 'package:bagtrip/plan_trip/models/budget_preset.dart';
import 'package:bagtrip/plan_trip/widgets/traveler_breakdown_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StepTravelersBudgetView extends StatelessWidget {
  const StepTravelersBudgetView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<PlanTripBloc, PlanTripState>(
      builder: (context, state) {
        final budgetOptions = [
          BudgetOption(
            label: l10n.budgetPresetBackpacker,
            emoji: '🎒',
            range: l10n.budgetPresetBackpackerDesc,
          ),
          BudgetOption(
            label: l10n.budgetPresetComfortable,
            emoji: '🏨',
            range: l10n.budgetPresetComfortableDesc,
          ),
          BudgetOption(
            label: l10n.budgetPresetPremium,
            emoji: '✨',
            range: l10n.budgetPresetPremiumDesc,
          ),
          BudgetOption(
            label: l10n.budgetPresetNoLimit,
            emoji: '💎',
            range: l10n.budgetPresetNoLimitDesc,
          ),
        ];

        final selectedBudgetIndex = state.budgetPreset != null
            ? BudgetPreset.values.indexOf(state.budgetPreset!)
            : null;

        final detailChip = formatTravelerBreakdownDetail(
          l10n,
          nbAdults: state.nbAdults,
          nbChildren: state.nbChildren,
          nbBabies: state.nbBabies,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
          ),
          children: [
            Text(
              l10n.travelersLabel,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorName.secondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),

            TravelerBreakdownCard(
              nbAdults: state.nbAdults,
              nbChildren: state.nbChildren,
              nbBabies: state.nbBabies,
              onAdultsChanged: (v) => context.read<PlanTripBloc>().add(
                PlanTripEvent.setTravelerCounts(adults: v),
              ),
              onChildrenChanged: (v) => context.read<PlanTripBloc>().add(
                PlanTripEvent.setTravelerCounts(children: v),
              ),
              onBabiesChanged: (v) => context.read<PlanTripBloc>().add(
                PlanTripEvent.setTravelerCounts(babies: v),
              ),
            ),

            if (detailChip.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space4),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space12,
                    vertical: AppSpacing.space8,
                  ),
                  decoration: BoxDecoration(
                    color: ColorName.secondary.withValues(alpha: 0.05),
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: ColorName.secondary),
                  ),
                  child: Text(
                    detailChip,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorName.primaryTrueDark,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.space16),

            Text(
              l10n.budgetLabel,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorName.secondary,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),

            BudgetPresetList(
              options: budgetOptions,
              selectedIndex: selectedBudgetIndex,
              onSelected: (index) {
                final preset = BudgetPreset.values[index];
                if (state.budgetPreset == preset) {
                  context.read<PlanTripBloc>().add(
                    const PlanTripEvent.setBudgetPreset(null),
                  );
                } else {
                  context.read<PlanTripBloc>().add(
                    PlanTripEvent.setBudgetPreset(preset),
                  );
                }
              },
            ),

            if (state.budgetPreset != null &&
                state.tripDurationDays != null) ...[
              const SizedBox(height: AppSpacing.space16),
              _BudgetEstimationBadge(
                preset: state.budgetPreset!,
                nbTravelers: state.nbTravelers,
                days: state.tripDurationDays!,
              ),
            ],

            const SizedBox(height: AppSpacing.space16),

            Center(
              child: TextButton(
                onPressed: () {
                  context.read<PlanTripBloc>().add(
                    const PlanTripEvent.setBudgetPreset(null),
                  );
                  context.read<PlanTripBloc>().add(
                    const PlanTripEvent.nextStep(),
                  );
                },
                child: Text(
                  l10n.budgetSkipLabel,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 14,
                    color: ColorName.hint,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.space16),

            _ContinueButton(
              onPressed: () {
                AppHaptics.medium();
                context.read<PlanTripBloc>().add(
                  const PlanTripEvent.nextStep(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _BudgetEstimationBadge extends StatelessWidget {
  final BudgetPreset preset;
  final int nbTravelers;
  final int days;

  const _BudgetEstimationBadge({
    required this.preset,
    required this.nbTravelers,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final range = estimateBudget(
      preset: preset,
      nbTravelers: nbTravelers,
      days: days,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: AppSpacing.allEdgeInsetSpace16,
      decoration: const BoxDecoration(
        color: ColorName.primaryLight,
        borderRadius: AppRadius.large16,
      ),
      child: Column(
        children: [
          Text(
            l10n.budgetEstimationLabel,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ColorName.secondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            l10n.budgetTotalRange(
              range.min.toStringAsFixed(0),
              range.max.toStringAsFixed(0),
              '€',
            ),
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ColorName.primaryTrueDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ContinueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ColorName.primary, ColorName.secondary],
        ),
        borderRadius: AppRadius.large16,
        boxShadow: [
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.3),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.large16,
          child: Center(
            child: Text(
              l10n.continueButton,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: FontFamily.b612,
                fontWeight: FontWeight.w600,
                color: ColorName.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
