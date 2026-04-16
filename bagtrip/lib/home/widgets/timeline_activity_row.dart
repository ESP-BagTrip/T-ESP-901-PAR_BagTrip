import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/material.dart';

class TimelineActivityRow extends StatefulWidget {
  final Activity activity;
  final bool isNext;
  final bool isLast;
  final bool isCurrent;
  final bool isPast;
  final int? minutesUntilNext;
  final int? remainingMinutes;
  final VoidCallback? onNavigate;

  const TimelineActivityRow({
    super.key,
    required this.activity,
    this.isNext = false,
    this.isLast = false,
    this.isCurrent = false,
    this.isPast = false,
    this.minutesUntilNext,
    this.remainingMinutes,
    this.onNavigate,
  });

  @override
  State<TimelineActivityRow> createState() => _TimelineActivityRowState();
}

class _TimelineActivityRowState extends State<TimelineActivityRow>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseOpacity;
  Animation<double>? _pulseScale;

  @override
  void initState() {
    super.initState();
    _setupPulseIfNeeded();
  }

  @override
  void didUpdateWidget(TimelineActivityRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCurrent != widget.isCurrent) {
      _disposePulse();
      _setupPulseIfNeeded();
    }
  }

  void _setupPulseIfNeeded() {
    if (widget.isCurrent) {
      _pulseController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      )..repeat(reverse: true);
      _pulseOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
      _pulseScale = Tween<double>(begin: 1.0, end: 1.4).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    }
  }

  void _disposePulse() {
    _pulseController?.dispose();
    _pulseController = null;
    _pulseOpacity = null;
    _pulseScale = null;
  }

  @override
  void dispose() {
    _disposePulse();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dimmedAlpha = 0.6;
    final isDimmed = widget.isPast && !widget.isCurrent && !widget.isNext;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline spine
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Top connector
                Expanded(
                  child: Container(
                    width: 2,
                    color: ColorName.primary.withValues(alpha: 0.2),
                  ),
                ),
                // Dot
                _buildDot(theme),
                // Bottom connector
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: ColorName.primary.withValues(alpha: 0.2),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),

          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space12,
              ),
              decoration: BoxDecoration(
                color: widget.isCurrent
                    ? theme.colorScheme.primaryContainer
                    : widget.isNext
                    ? ColorName.primary.withValues(alpha: 0.05)
                    : theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: AppRadius.medium8,
                border: Border.all(
                  color: widget.isCurrent
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : widget.isNext
                      ? ColorName.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Time or all-day label
                      SizedBox(
                        width: 48,
                        child: Text(
                          widget.activity.startTime ?? l10n.activeTripsAllDay,
                          style: TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDimmed
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: dimmedAlpha,
                                  )
                                : widget.isCurrent || widget.isNext
                                ? ColorName.primary
                                : ColorName.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      // Title
                      Expanded(
                        child: Text(
                          widget.activity.title,
                          style: TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 14,
                            color: isDimmed
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: dimmedAlpha,
                                  )
                                : theme.colorScheme.onSurface,
                            fontWeight: widget.isCurrent || widget.isNext
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // "In X min" badge for next activity
                      if (widget.isNext && widget.minutesUntilNext != null) ...[
                        const SizedBox(width: AppSpacing.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ColorName.primary.withValues(alpha: 0.08),
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            l10n.timelineInMinutes(widget.minutesUntilNext!),
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 11,
                              color: ColorName.primary,
                            ),
                          ),
                        ),
                      ],
                      // "In progress" badge for current activity
                      if (widget.isCurrent && _pulseOpacity != null) ...[
                        const SizedBox(width: AppSpacing.space8),
                        AnimatedBuilder(
                          animation: _pulseOpacity!,
                          builder: (context, child) => Opacity(
                            opacity: _pulseOpacity!.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(
                                l10n.timelineInProgress,
                                style: TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.space8),
                      // Category icon
                      Icon(
                        widget.activity.category.icon,
                        size: 18,
                        color: isDimmed
                            ? theme.colorScheme.outline.withValues(
                                alpha: dimmedAlpha,
                              )
                            : theme.colorScheme.outline,
                      ),
                    ],
                  ),
                  // Remaining minutes + navigate for current activity
                  if (widget.isCurrent) ...[
                    if (widget.remainingMinutes != null) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        l10n.timelineRemainingMinutes(widget.remainingMinutes!),
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (widget.onNavigate != null) ...[
                      const SizedBox(height: AppSpacing.space8),
                      SizedBox(
                        height: 32,
                        child: TextButton.icon(
                          onPressed: widget.onNavigate,
                          icon: const Icon(Icons.navigation_outlined, size: 16),
                          label: Text(
                            l10n.timelineNavigate,
                            style: const TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  // Navigate icon for non-current rows with location
                  if (!widget.isCurrent &&
                      widget.onNavigate != null &&
                      widget.activity.location != null &&
                      widget.activity.location!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space4),
                    GestureDetector(
                      onTap: widget.onNavigate,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.navigation_outlined,
                            size: 14,
                            color: isDimmed
                                ? theme.colorScheme.outline.withValues(
                                    alpha: dimmedAlpha,
                                  )
                                : theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.timelineNavigate,
                            style: TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 11,
                              color: isDimmed
                                  ? theme.colorScheme.outline.withValues(
                                      alpha: dimmedAlpha,
                                    )
                                  : theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(ThemeData theme) {
    if (widget.isCurrent && _pulseScale != null) {
      return SizedBox(
        width: 20,
        height: 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            AnimatedBuilder(
              animation: _pulseScale!,
              builder: (context, child) => Transform.scale(
                scale: _pulseScale!.value,
                child: Opacity(
                  opacity: 1.0 - (_pulseScale!.value - 1.0) / 0.4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Solid dot
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    final dotSize = widget.isNext ? 12.0 : 8.0;
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isNext ? ColorName.primary : Colors.transparent,
        border: widget.isNext
            ? null
            : Border.all(
                color: widget.isPast
                    ? ColorName.primary.withValues(alpha: 0.2)
                    : ColorName.primary.withValues(alpha: 0.4),
                width: 2,
              ),
      ),
    );
  }
}
