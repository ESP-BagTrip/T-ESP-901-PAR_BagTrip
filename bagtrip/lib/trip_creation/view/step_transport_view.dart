import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_creation/bloc/trip_creation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StepTransportView extends StatelessWidget {
  const StepTransportView({super.key});

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
                  Icons.directions_rounded,
                  size: 18,
                  color: ColorName.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.transportTitle,
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

            // Flight option
            _TransportOptionCard(
              icon: Icons.flight_rounded,
              title: l10n.transportOptionFlightTitle,
              subtitle: l10n.transportOptionFlightSubtitle,
              isSelected: state.transportChoice == TransportChoice.flight,
              isPrimary: true,
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<TripCreationBloc>().add(
                  SetTransport(TransportChoice.flight),
                );
              },
            ),
            const SizedBox(height: 12),

            // Other transport option
            _TransportOptionCard(
              icon: Icons.directions_car_rounded,
              title: l10n.transportOptionOtherTitle,
              subtitle: l10n.transportOptionOtherSubtitle,
              isSelected: state.transportChoice == TransportChoice.other,
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<TripCreationBloc>().add(
                  SetTransport(TransportChoice.other),
                );
              },
            ),
            const SizedBox(height: 12),

            // Skip option
            _TransportOptionCard(
              icon: Icons.skip_next_rounded,
              title: l10n.transportOptionSkipTitle,
              subtitle: l10n.transportOptionSkipSubtitle,
              isSelected: state.transportChoice == TransportChoice.skip,
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<TripCreationBloc>().add(
                  SetTransport(TransportChoice.skip),
                );
              },
            ),

            const SizedBox(height: 32),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: _BackButton(
                    onPressed: () =>
                        context.read<TripCreationBloc>().add(PreviousStep()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _NextButton(
                    enabled: state.transportChoice != null,
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

class _TransportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isPrimary;
  final VoidCallback onTap;

  const _TransportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large16,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? (isPrimary ? null : ColorName.primaryLight)
                : ColorName.surface,
            gradient: isSelected && isPrimary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ColorName.primary, ColorName.secondary],
                  )
                : null,
            borderRadius: AppRadius.large16,
            border: Border.all(
              color: isSelected
                  ? ColorName.primary
                  : ColorName.primarySoftLight,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? ColorName.primary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 4),
                blurRadius: isSelected ? 12 : 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected && isPrimary
                      ? ColorName.surface.withValues(alpha: 0.25)
                      : isSelected
                      ? ColorName.primary.withValues(alpha: 0.15)
                      : ColorName.surfaceLight,
                  borderRadius: AppRadius.medium8,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected && isPrimary
                      ? ColorName.surface
                      : isSelected
                      ? ColorName.primary
                      : ColorName.primaryTrueDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected && isPrimary
                            ? ColorName.surface
                            : ColorName.primaryTrueDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        color: isSelected && isPrimary
                            ? ColorName.surface.withValues(alpha: 0.8)
                            : ColorName.hint,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: isSelected && isPrimary
                      ? ColorName.surface
                      : ColorName.primary,
                ),
            ],
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
  final bool enabled;

  const _NextButton({required this.onPressed, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
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
            onTap: enabled ? onPressed : null,
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
      ),
    );
  }
}
