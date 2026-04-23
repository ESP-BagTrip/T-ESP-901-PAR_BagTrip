import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/flexible_date_picker.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StepDatesView extends StatelessWidget {
  const StepDatesView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<PlanTripBloc, PlanTripState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space22,
            AppSpacing.space22,
            AppSpacing.space22,
            AppSpacing.space40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.pill,
                      border: Border.all(color: ColorName.secondary),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: ColorName.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Text(
                    l10n.datesLabel,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorName.secondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),

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

              const SizedBox(height: AppSpacing.space32),

              _ContinueButton(
                enabled: state.areDatesValid,
                onPressed: () {
                  AppHaptics.medium();
                  context.read<PlanTripBloc>().add(
                    const PlanTripEvent.nextStep(),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.space32),
            ],
          ),
        );
      },
    );
  }
}

class _ScaleInBadge extends StatefulWidget {
  const _ScaleInBadge({required this.child});

  final Widget child;

  @override
  State<_ScaleInBadge> createState() => _ScaleInBadgeState();
}

class _ScaleInBadgeState extends State<_ScaleInBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.badgeScaleIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      child: widget.child,
    );
  }
}

class _ContinueButton extends StatefulWidget {
  const _ContinueButton({required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final child = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: widget.enabled
            ? const LinearGradient(
                colors: [ColorName.primary, ColorName.secondary],
              )
            : null,
        color: widget.enabled
            ? null
            : ColorName.secondary.withValues(alpha: 0.1),
        borderRadius: AppRadius.pill,
        boxShadow: widget.enabled
            ? [
                BoxShadow(
                  color: ColorName.primary.withValues(alpha: 0.3),
                  offset: const Offset(0, 6),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? widget.onPressed : null,
          borderRadius: AppRadius.pill,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space22,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.continueButton,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontWeight: FontWeight.w600,
                      color: widget.enabled
                          ? ColorName.surface
                          : ColorName.hint,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: _hover && widget.enabled ? 1 : 0,
                    ),
                    duration: AppAnimations.microInteraction,
                    builder: (context, t, child) {
                      return Transform.translate(
                        offset: Offset(4 * t, 0),
                        child: child,
                      );
                    },
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: widget.enabled
                          ? ColorName.surface
                          : ColorName.hint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) {
        if (widget.enabled) setState(() => _hover = true);
      },
      onExit: (_) => setState(() => _hover = false),
      child: child,
    );
  }
}
