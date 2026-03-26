import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:flutter/material.dart';

class TripCompletionBar extends StatefulWidget {
  final int percentage;
  final Map<CompletionSegmentType, bool> segments;
  final ValueChanged<CompletionSegmentType>? onSegmentTap;

  const TripCompletionBar({
    super.key,
    required this.percentage,
    required this.segments,
    this.onSegmentTap,
  });

  @override
  State<TripCompletionBar> createState() => _TripCompletionBarState();
}

class _TripCompletionBarState extends State<TripCompletionBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final segmentTypes = CompletionSegmentType.values;

    return Row(
      children: [
        Text(
          '${widget.percentage}%',
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ColorName.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: Row(
            children: List.generate(segmentTypes.length, (i) {
              final type = segmentTypes[i];
              final isFilled = widget.segments[type] ?? false;

              // Staggered animation: each segment starts after the previous
              final begin = i / segmentTypes.length;
              final end = (i + 1) / segmentTypes.length;
              final animation = CurvedAnimation(
                parent: _controller,
                curve: Interval(begin, end, curve: Curves.easeOutCubic),
              );

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    AppHaptics.light();
                    widget.onSegmentTap?.call(type);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < segmentTypes.length - 1 ? 3 : 0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconForType(type),
                          size: 14,
                          color: isFilled
                              ? ColorName.primary
                              : ColorName.shimmerBase,
                        ),
                        const SizedBox(height: 3),
                        AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: isFilled
                                    ? ColorName.primary.withValues(
                                        alpha: animation.value,
                                      )
                                    : ColorName.shimmerBase,
                                borderRadius: AppRadius.pill,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _labelForType(type, l10n),
                          style: TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 10,
                            color: isFilled
                                ? ColorName.primary
                                : ColorName.shimmerBase,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  static IconData _iconForType(CompletionSegmentType type) {
    return switch (type) {
      CompletionSegmentType.dates => Icons.calendar_today_rounded,
      CompletionSegmentType.flights => Icons.flight_rounded,
      CompletionSegmentType.accommodation => Icons.hotel_rounded,
      CompletionSegmentType.activities => Icons.hiking_rounded,
      CompletionSegmentType.baggage => Icons.luggage_rounded,
      CompletionSegmentType.budget => Icons.wallet_rounded,
    };
  }

  static String _labelForType(
    CompletionSegmentType type,
    AppLocalizations l10n,
  ) {
    return switch (type) {
      CompletionSegmentType.dates => l10n.completionDates,
      CompletionSegmentType.flights => l10n.completionFlights,
      CompletionSegmentType.accommodation => l10n.completionAccommodation,
      CompletionSegmentType.activities => l10n.completionActivities,
      CompletionSegmentType.baggage => l10n.completionBaggage,
      CompletionSegmentType.budget => l10n.completionBudget,
    };
  }
}
