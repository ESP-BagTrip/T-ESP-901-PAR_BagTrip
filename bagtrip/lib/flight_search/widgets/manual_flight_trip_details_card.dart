import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Trip details card: Passengers row + Max budget row + inline slider.
class ManualFlightTripDetailsCard extends StatelessWidget {
  const ManualFlightTripDetailsCard({super.key, required this.state});

  final FlightSearchLoaded state;

  static const double _budgetMin = 50;
  static const double _budgetMax = 2000;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tripDetailsLabel.toUpperCase(),
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ColorName.hint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: ColorName.surface,
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            children: [
              _PassengersRow(
                summary: _passengerSummary(l10n),
                onTap: () => _showPassengersSheet(context),
              ),
              Divider(
                height: 1,
                color: ColorName.primarySoftLight.withValues(alpha: 0.6),
              ),
              _ExpandableBudgetSection(
                value: (state.maxPrice ?? 500).clamp(_budgetMin, _budgetMax),
                budgetMin: _budgetMin,
                budgetMax: _budgetMax,
                onChanged:
                    (v) => context.read<FlightSearchBloc>().add(SetMaxPrice(v)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _passengerSummary(AppLocalizations l10n) {
    final parts = <String>[];
    if (state.adults > 0) {
      parts.add(
        state.adults == 1
            ? l10n.passengersAdults
            : '${state.adults} ${l10n.passengersAdults}',
      );
    }
    if (state.children > 0) {
      parts.add(
        state.children == 1
            ? l10n.passengersChildren
            : '${state.children} ${l10n.passengersChildren}',
      );
    }
    if (state.infants > 0) {
      parts.add(
        state.infants == 1
            ? l10n.passengersInfants
            : '${state.infants} ${l10n.passengersInfants}',
      );
    }
    return parts.isEmpty ? '1 ${l10n.passengersAdults}' : parts.join(', ');
  }

  void _showPassengersSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<FlightSearchBloc>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => BlocProvider.value(
            value: bloc,
            child: BlocBuilder<FlightSearchBloc, FlightSearchState>(
              builder: (context, sheetState) {
                final s = sheetState is FlightSearchLoaded ? sheetState : state;
                return Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.passengersTitle,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: ColorName.primaryTrueDark,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _PassengerSheetRow(
                            label: l10n.passengersAdults,
                            description: l10n.passengersAdultsDesc,
                            value: s.adults,
                            onAdd:
                                () => context.read<FlightSearchBloc>().add(
                                  SetAdults(s.adults + 1),
                                ),
                            onRemove:
                                () => context.read<FlightSearchBloc>().add(
                                  SetAdults(s.adults > 1 ? s.adults - 1 : 1),
                                ),
                          ),
                          _PassengerSheetRow(
                            label: l10n.passengersChildren,
                            description: l10n.passengersChildrenDesc,
                            value: s.children,
                            onAdd:
                                () => context.read<FlightSearchBloc>().add(
                                  SetChildren(s.children + 1),
                                ),
                            onRemove:
                                () => context.read<FlightSearchBloc>().add(
                                  SetChildren(
                                    s.children > 0 ? s.children - 1 : 0,
                                  ),
                                ),
                          ),
                          _PassengerSheetRow(
                            label: l10n.passengersInfants,
                            description: l10n.passengersInfantsDesc,
                            value: s.infants,
                            onAdd:
                                () => context.read<FlightSearchBloc>().add(
                                  SetInfants(s.infants + 1),
                                ),
                            onRemove:
                                () => context.read<FlightSearchBloc>().add(
                                  SetInfants(s.infants > 0 ? s.infants - 1 : 0),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }
}

class _PassengersRow extends StatelessWidget {
  const _PassengersRow({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large24,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 22,
                color: ColorName.primaryTrueDark,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.passengersTitle,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: ColorName.hint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ColorName.primaryTrueDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ColorName.hint,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Budget section dépliable : chevron droite quand replié, chevron bas quand déplié.
class _ExpandableBudgetSection extends StatefulWidget {
  const _ExpandableBudgetSection({
    required this.value,
    required this.budgetMin,
    required this.budgetMax,
    required this.onChanged,
  });

  final double value;
  final double budgetMin;
  final double budgetMax;
  final ValueChanged<double> onChanged;

  @override
  State<_ExpandableBudgetSection> createState() =>
      _ExpandableBudgetSectionState();
}

class _ExpandableBudgetSectionState extends State<_ExpandableBudgetSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: AppRadius.large24,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.savings_outlined,
                    size: 22,
                    color: ColorName.secondary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.maxBudgetLabel,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 13,
                            color: ColorName.hint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '€${widget.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ColorName.primaryTrueDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.chevron_right_rounded,
                    color: ColorName.hint,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BudgetSlider(
              value: widget.value,
              onChanged: widget.onChanged,
              budgetMin: widget.budgetMin,
              budgetMax: widget.budgetMax,
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _BudgetSlider extends StatelessWidget {
  const _BudgetSlider({
    required this.value,
    required this.onChanged,
    required this.budgetMin,
    required this.budgetMax,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double budgetMin;
  final double budgetMax;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '€${value.toStringAsFixed(0)}',
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ColorName.secondary,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: ColorName.secondary,
            inactiveTrackColor: ColorName.primaryLight,
            thumbColor: ColorName.surface,
            overlayColor: ColorName.secondary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: budgetMin,
            max: budgetMax,
            divisions: 39,
            onChanged: onChanged,
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '€50',
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                color: AppColors.hint,
              ),
            ),
            Text(
              '€500',
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                color: AppColors.hint,
              ),
            ),
            Text(
              '€1,000',
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                color: AppColors.hint,
              ),
            ),
            Text(
              'Max €2,000',
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                color: AppColors.hint,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PassengerSheetRow extends StatelessWidget {
  const _PassengerSheetRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final String description;
  final int value;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorName.primaryTrueDark,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    color: AppColors.hint,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _CircleButton(icon: Icons.remove_rounded, onTap: onRemove),
              const SizedBox(width: 16),
              SizedBox(
                width: 32,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorName.primaryTrueDark,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _CircleButton(
                icon: Icons.add_rounded,
                onTap: onAdd,
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color:
              filled
                  ? ColorName.primary
                  : ColorName.primaryLight.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: filled ? ColorName.surface : ColorName.primaryTrueDark,
        ),
      ),
    );
  }
}
