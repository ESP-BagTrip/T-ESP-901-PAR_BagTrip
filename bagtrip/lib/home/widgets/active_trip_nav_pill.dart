import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Teal pulsing dot + title; returns to idle home without ending the trip.
class ActiveTripNavPill extends StatefulWidget {
  const ActiveTripNavPill({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<ActiveTripNavPill> createState() => _ActiveTripNavPillState();
}

class _ActiveTripNavPillState extends State<ActiveTripNavPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          if (widget.onTap != null) {
            widget.onTap!();
            return;
          }
          context.read<HomeBloc>().add(PreferIdleHomeOverview());
        },
        borderRadius: AppRadius.large24,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.large24,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space16,
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final t = CurvedAnimation(
                      parent: _pulse,
                      curve: Curves.easeInOut,
                    ).value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: 1.0 + 0.35 * t,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ColorName.primary.withValues(
                                alpha: 0.25 * (1 - t),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorName.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeNavPillTitle,
                        style: TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.homeNavPillSubtitle,
                        style: TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 12,
                          height: 1.25,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
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
