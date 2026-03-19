import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/pages/create_trip_ai_flow_page.dart';
import 'package:bagtrip/trip_creation/bloc/trip_creation_bloc.dart';
import 'package:bagtrip/trip_creation/widgets/destination_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StepDestinationView extends StatelessWidget {
  const StepDestinationView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<TripCreationBloc, TripCreationState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // Section label
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: ColorName.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.destinationLabel,
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
            const SizedBox(height: 8),

            // Autocomplete search field
            DestinationSearchField(hintText: l10n.destinationPlaceholder),

            // Selected destination display
            if (state.destinationName != null) ...[
              const SizedBox(height: 12),
              _SelectedDestinationChip(
                name: state.destinationName!,
                country: state.destinationCountry ?? '',
                iata: state.destinationIata ?? '',
                onClear: () =>
                    context.read<TripCreationBloc>().add(ClearDestination()),
              ),
            ],

            const SizedBox(height: AppSpacing.space24),

            // "Inspire-moi" — navigate to AI planning flow
            _InspireMeButton(
              isLoading: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateTripAiFlowPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Next button
            _NextButton(
              enabled: state.isDestinationValid,
              onPressed: () => context.read<TripCreationBloc>().add(NextStep()),
            ),
          ],
        );
      },
    );
  }
}

class _SelectedDestinationChip extends StatelessWidget {
  final String name;
  final String country;
  final String iata;
  final VoidCallback onClear;

  const _SelectedDestinationChip({
    required this.name,
    required this.country,
    required this.iata,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorName.primaryLight,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: ColorName.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ColorName.primaryTrueDark,
                  ),
                ),
                if (iata.isNotEmpty || country.isNotEmpty)
                  Text(
                    [iata, country].where((e) => e.isNotEmpty).join(' \u2022 '),
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      color: ColorName.hint,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: ColorName.hint,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspireMeButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _InspireMeButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: AppRadius.large16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ColorName.surface,
                  ),
                )
              else
                const Icon(
                  Icons.auto_awesome,
                  color: ColorName.surface,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Text(
                l10n.inspireMe,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ColorName.surface,
                ),
              ),
            ],
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
        width: double.infinity,
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
