import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/budget_chip_selector.dart';
import 'package:bagtrip/design/widgets/budget_preset_list.dart';
import 'package:bagtrip/design/widgets/progression_cta_button.dart';
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

class StepTravelersBudgetView extends StatefulWidget {
  const StepTravelersBudgetView({super.key});

  @override
  State<StepTravelersBudgetView> createState() =>
      _StepTravelersBudgetViewState();
}

class _StepTravelersBudgetViewState extends State<StepTravelersBudgetView> {
  final TextEditingController _originController = TextEditingController();
  final FocusNode _originFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _originFocus.addListener(() => setState(() {}));
    final origin = context.read<PlanTripBloc>().state.originCity;
    if (origin != null && origin.isNotEmpty) {
      _originController.text = origin;
    }
  }

  @override
  void dispose() {
    _originFocus.dispose();
    _originController.dispose();
    super.dispose();
  }

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

        final focused = _originFocus.hasFocus;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            // ── Origin city ──────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.flight_takeoff_rounded,
                  size: 16,
                  color: ColorName.secondary,
                ),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  l10n.originCityLabel,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorName.secondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),

            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: AppRadius.large16,
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: ColorName.secondary.withValues(alpha: 0.18),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: ColorName.surface,
                  borderRadius: AppRadius.large16,
                  border: Border.all(
                    color: focused
                        ? ColorName.secondary.withValues(alpha: 0.45)
                        : ColorName.primarySoftLight,
                  ),
                ),
                child: TextField(
                  controller: _originController,
                  focusNode: _originFocus,
                  onChanged: (v) {
                    context.read<PlanTripBloc>().add(
                      PlanTripEvent.searchOrigin(v.trim()),
                    );
                  },
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 16,
                    color: PersonalizationColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.originCityPlaceholder,
                    hintStyle: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: ColorName.hint,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 10),
                      child: Icon(
                        Icons.location_city_rounded,
                        size: 20,
                        color: ColorName.hint,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    suffixIcon: _originController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _originController.clear();
                              context.read<PlanTripBloc>().add(
                                const PlanTripEvent.setOriginCity(''),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: ColorName.hint,
                              ),
                            ),
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Autocomplete suggestions
            if (state.originSearchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.space4),
                decoration: BoxDecoration(
                  color: ColorName.surface,
                  borderRadius: AppRadius.large16,
                  border: Border.all(color: ColorName.primarySoftLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: state.originSearchResults.asMap().entries.map((
                    entry,
                  ) {
                    final idx = entry.key;
                    final loc = entry.value;
                    return Column(
                      children: [
                        if (idx > 0)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE8EAED),
                          ),
                        InkWell(
                          onTap: () {
                            AppHaptics.light();
                            _originController.text = loc.name;
                            _originFocus.unfocus();
                            context.read<PlanTripBloc>().add(
                              PlanTripEvent.setOriginCity(loc.name),
                            );
                          },
                          borderRadius: idx == 0
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                )
                              : idx == state.originSearchResults.length - 1
                              ? const BorderRadius.vertical(
                                  bottom: Radius.circular(16),
                                )
                              : BorderRadius.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space16,
                              vertical: AppSpacing.space12,
                            ),
                            child: Row(
                              children: [
                                if (loc.countryCode.length == 2) ...[
                                  Text(
                                    _countryCodeToFlag(loc.countryCode),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: AppSpacing.space12),
                                ],
                                Expanded(
                                  child: Text(
                                    loc.countryName.isNotEmpty
                                        ? '${loc.name}, ${loc.countryName}'
                                        : loc.name,
                                    style: const TextStyle(
                                      fontFamily: FontFamily.dMSerifDisplay,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: ColorName.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: AppSpacing.space24),

            // ── Travelers ────────────────────────────────────
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

            ProgressionCtaButton(
              text: l10n.continueButton,
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                AppHaptics.medium();
                context.read<PlanTripBloc>().add(
                  const PlanTripEvent.nextStep(),
                );
              },
            ),

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
                    fontFamily: FontFamily.dMSans,
                    fontSize: 14,
                    color: ColorName.primaryDark,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _countryCodeToFlag(String code) {
    if (code.length != 2) return '';
    return String.fromCharCodes([
      code.codeUnitAt(0) - 0x41 + 0x1F1E6,
      code.codeUnitAt(1) - 0x41 + 0x1F1E6,
    ]);
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
