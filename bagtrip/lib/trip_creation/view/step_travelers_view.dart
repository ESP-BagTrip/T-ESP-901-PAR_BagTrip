import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_creation/bloc/trip_creation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StepTravelersView extends StatelessWidget {
  const StepTravelersView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<TripCreationBloc, TripCreationState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  size: 18,
                  color: ColorName.secondary,
                ),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  l10n.numberOfTravelersLabel,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorName.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space16),

            // Traveler chips
            Row(
              children: [
                for (int i = 1; i <= 4; i++) ...[
                  if (i > 1) const SizedBox(width: AppSpacing.space8),
                  Expanded(
                    child: _TravelerChip(
                      label: '$i',
                      selected: state.nbTravelers == i,
                      onTap: () =>
                          context.read<TripCreationBloc>().add(SetTravelers(i)),
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.space8),
                Expanded(
                  child: _TravelerChip(
                    label: l10n.travelerCount5Plus,
                    selected: state.nbTravelers >= 5,
                    onTap: () =>
                        context.read<TripCreationBloc>().add(SetTravelers(5)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space32),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: _BackButton(
                    onPressed: () =>
                        context.read<TripCreationBloc>().add(PreviousStep()),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  flex: 2,
                  child: _NextButton(
                    onPressed: () =>
                        context.read<TripCreationBloc>().add(NextStep()),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TravelerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TravelerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: Container(
          padding: AppSpacing.verticalSpace16,
          decoration: BoxDecoration(
            color: selected ? ColorName.primary : ColorName.surfaceLight,
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: selected
                  ? ColorName.primary
                  : ColorName.primarySoftLight.withValues(alpha: 0.6),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? ColorName.surface : ColorName.primaryTrueDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: const Center(
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: ColorName.primaryTrueDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NextButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ColorName.primary, ColorName.secondary],
        ),
        borderRadius: BorderRadius.circular(24),
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
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: Text(
              l10n.nextButton,
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
