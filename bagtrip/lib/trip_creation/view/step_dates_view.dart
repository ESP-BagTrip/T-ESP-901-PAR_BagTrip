import 'package:bagtrip/components/custom_calendar_picker.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_creation/bloc/trip_creation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class StepDatesView extends StatelessWidget {
  const StepDatesView({super.key});

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
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: ColorName.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.datesLabel,
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

            // AI suggestion hint
            if (state.selectedAiProposal != null &&
                state.selectedAiProposal!.durationDays > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: ColorName.primaryLight,
                  borderRadius: AppRadius.large16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: ColorName.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.suggestedDuration}: ${state.selectedAiProposal!.durationDays} ${l10n.days}',
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: ColorName.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
            ],

            // Date pickers
            Row(
              children: [
                Expanded(
                  child: _DateCard(
                    label: l10n.departLabel,
                    date: state.startDate,
                    hint: l10n.dateFormatHint,
                    onTap: () => _pickDates(context, state),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateCard(
                    label: l10n.returnLabel,
                    date: state.endDate,
                    hint: l10n.dateFormatHint,
                    onTap: () => _pickDates(context, state),
                  ),
                ),
              ],
            ),

            // Duration display
            if (state.startDate != null && state.endDate != null) ...[
              const SizedBox(height: AppSpacing.space16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ColorName.surface,
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: ColorName.primarySoftLight),
                  ),
                  child: Text(
                    '${state.endDate!.difference(state.startDate!).inDays} ${l10n.days}',
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorName.primaryTrueDark,
                    ),
                  ),
                ),
              ),
            ],

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
                    enabled: state.areDatesValid,
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

  Future<void> _pickDates(BuildContext context, TripCreationState state) async {
    final result = await showCustomCalendarPicker(
      context: context,
      initialDate: state.startDate ?? DateTime.now(),
      initialEndDate: state.endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      isRangeSelection: true,
    );
    if (result != null && context.mounted) {
      context.read<TripCreationBloc>().add(
        SetDates(
          start: result.startDate,
          end: result.endDate ?? result.startDate,
        ),
      );
    }
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;

  const _DateCard({
    required this.label,
    this.date,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = date != null
        ? DateFormat('dd/MM/yyyy').format(date!)
        : hint;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large16,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorName.surfaceLight,
            borderRadius: AppRadius.large16,
            border: Border.all(
              color: ColorName.primarySoftLight.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: ColorName.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ColorName.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                displayText,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: date != null
                      ? ColorName.primaryTrueDark
                      : ColorName.hint,
                ),
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
