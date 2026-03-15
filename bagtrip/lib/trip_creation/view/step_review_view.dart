import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_creation/bloc/trip_creation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class StepReviewView extends StatelessWidget {
  const StepReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<TripCreationBloc, TripCreationState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // Title
            Text(
              l10n.reviewTitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ColorName.primaryTrueDark,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),

            // Destination
            _ReviewItem(
              icon: Icons.location_on_rounded,
              label: l10n.destinationLabel,
              value: [
                state.destinationName ?? '',
                if (state.destinationCountry != null &&
                    state.destinationCountry!.isNotEmpty)
                  state.destinationCountry!,
              ].join(', '),
            ),
            const SizedBox(height: 16),

            // Dates
            if (state.startDate != null && state.endDate != null)
              _ReviewItem(
                icon: Icons.calendar_today_rounded,
                label: l10n.datesLabel,
                value:
                    '${DateFormat('dd/MM/yyyy').format(state.startDate!)} - ${DateFormat('dd/MM/yyyy').format(state.endDate!)}',
                trailing:
                    '${state.endDate!.difference(state.startDate!).inDays} ${l10n.days}',
              ),
            const SizedBox(height: 16),

            // Travelers
            _ReviewItem(
              icon: Icons.people_outline_rounded,
              label: l10n.numberOfTravelersLabel,
              value: state.nbTravelers >= 5
                  ? l10n.travelerCount5Plus
                  : '${state.nbTravelers}',
            ),
            const SizedBox(height: 16),

            // AI highlights
            if (state.selectedAiProposal != null) ...[
              const SizedBox(height: AppSpacing.space24),
              const Divider(),
              const SizedBox(height: AppSpacing.space16),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: ColorName.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.aiSuggestionsTitle,
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
              const SizedBox(height: 12),
              if (state.selectedAiProposal!.description.isNotEmpty)
                Text(
                  state.selectedAiProposal!.description,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 14,
                    color: ColorName.textMutedLight,
                  ),
                ),
              if (state.selectedAiProposal!.activities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.selectedAiProposal!.activities
                      .take(4)
                      .map(
                        (a) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: const BoxDecoration(
                            color: ColorName.primaryLight,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (a['title'] ?? '').toString(),
                                style: const TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: ColorName.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: const BoxDecoration(
                                  color: ColorName.secondaryLight,
                                  borderRadius: AppRadius.pill,
                                ),
                                child: Text(
                                  l10n.toValidateBadge,
                                  style: const TextStyle(
                                    fontFamily: FontFamily.b612,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: ColorName.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],

            const SizedBox(height: 32),

            // Error message
            if (state.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: AppRadius.medium8,
                ),
                child: Text(
                  state.error!,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                  child: _CreateButton(
                    isLoading: state.isCreating,
                    onPressed: () => context.read<TripCreationBloc>().add(
                      CreateTripFromFlow(),
                    ),
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

class _ReviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trailing;

  const _ReviewItem({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: ColorName.primaryLight,
              borderRadius: AppRadius.medium8,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: ColorName.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ColorName.secondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ColorName.primaryTrueDark,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: ColorName.primaryLight,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                trailing!,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorName.primary,
                ),
              ),
            ),
        ],
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

class _CreateButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _CreateButton({required this.onPressed, this.isLoading = false});

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
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorName.surface,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        color: ColorName.surface,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.createTripButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: FontFamily.b612,
                          fontWeight: FontWeight.w600,
                          color: ColorName.surface,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
