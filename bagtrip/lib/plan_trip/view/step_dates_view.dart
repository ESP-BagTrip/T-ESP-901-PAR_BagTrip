import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/flexible_date_picker.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/date_mode.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class StepDatesView extends StatelessWidget {
  const StepDatesView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<PlanTripBloc, PlanTripState>(
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
                const SizedBox(width: AppSpacing.space8),
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

            // FlexibleDatePicker
            FlexibleDatePicker(
              mode: state.dateMode,
              onModeChanged: (mode) => context.read<PlanTripBloc>().add(
                PlanTripEvent.setDateMode(mode),
              ),
              startDate: state.startDate,
              endDate: state.endDate,
              onDatesChanged: (start, end) {
                if (start != null && end != null) {
                  context.read<PlanTripBloc>().add(
                    PlanTripEvent.setExactDates(start, end),
                  );
                }
              },
              selectedMonth: state.preferredMonth,
              selectedYear: state.preferredYear,
              onMonthSelected: (month, year) => context
                  .read<PlanTripBloc>()
                  .add(PlanTripEvent.setMonthPreference(month, year)),
              selectedDuration: state.flexibleDuration,
              onDurationChanged: (preset) => context.read<PlanTripBloc>().add(
                PlanTripEvent.setFlexibleDuration(preset),
              ),
            ),

            // Dynamic resume badge
            if (state.areDatesValid) ...[
              const SizedBox(height: AppSpacing.space24),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space16,
                    vertical: AppSpacing.space8,
                  ),
                  decoration: BoxDecoration(
                    color: ColorName.surface,
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: ColorName.primarySoftLight),
                  ),
                  child: Text(
                    _buildResume(state, l10n, context),
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

            const SizedBox(height: AppSpacing.space32),

            // Continue button
            _ContinueButton(
              enabled: state.areDatesValid,
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

  String _buildResume(
    PlanTripState state,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    final locale = Localizations.localeOf(context).toString();
    switch (state.dateMode) {
      case DateMode.exact:
        if (state.startDate != null && state.endDate != null) {
          final fmt = DateFormat('d MMM yyyy', locale);
          return '${fmt.format(state.startDate!)} - ${fmt.format(state.endDate!)}';
        }
        return '';
      case DateMode.month:
        if (state.preferredMonth != null && state.preferredYear != null) {
          final d = DateTime(state.preferredYear!, state.preferredMonth!);
          final fmt = DateFormat('MMMM yyyy', locale);
          return fmt.format(d);
        }
        return '';
      case DateMode.flexible:
        return switch (state.flexibleDuration) {
          DurationPreset.weekend => l10n.datesFlexibleWeekend,
          DurationPreset.oneWeek => l10n.datesFlexibleWeek,
          DurationPreset.twoWeeks => l10n.datesFlexibleTwoWeeks,
          DurationPreset.threeWeeks => l10n.datesFlexibleThreeWeeks,
          null => '',
        };
    }
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const _ContinueButton({required this.onPressed, this.enabled = true});

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
      ),
    );
  }
}
