import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/timeline_activity_accent.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/material.dart';

const Color _timelineGrey = Color(0xFFB0B8C4);

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
      _pulseOpacity = Tween<double>(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
      _pulseScale = Tween<double>(begin: 1.0, end: 1.35).animate(
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

  Color _accent(bool isDimmed) {
    final base = timelineCardAccent(
      activity: widget.activity,
      isNow: widget.isCurrent,
    );
    return isDimmed ? base.withValues(alpha: 0.5) : base;
  }

  String? _subtitleLine(AppLocalizations l10n) {
    final desc = widget.activity.description?.trim();
    if (desc != null && desc.isNotEmpty) return desc;
    final loc = widget.activity.location?.trim();
    if (loc != null && loc.isNotEmpty) return loc;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dimmedAlpha = 0.55;
    final isDimmed = widget.isPast && !widget.isCurrent && !widget.isNext;

    final spineColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.6);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Expanded(child: Container(width: 2, color: spineColor)),
                _buildDot(isDimmed),
                if (!widget.isLast)
                  Expanded(child: Container(width: 2, color: spineColor))
                else
                  const Spacer(),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: _buildCardShell(
              theme: theme,
              l10n: l10n,
              isDimmed: isDimmed,
              dimmedAlpha: dimmedAlpha,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardShell({
    required ThemeData theme,
    required AppLocalizations l10n,
    required bool isDimmed,
    required double dimmedAlpha,
  }) {
    final accent = _accent(isDimmed);
    final capsuleLabel = widget.isCurrent
        ? l10n.homeSectionNowBadge
        : (widget.activity.startTime ?? l10n.activeTripsAllDay);
    final subtitle = _subtitleLine(l10n);

    final inner = Padding(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _timeCapsule(capsuleLabel, accent, isDimmed),
              const SizedBox(width: AppSpacing.space8),
              _iconCircle(theme, accent, isDimmed),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            widget.activity.title,
            style: TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDimmed
                  ? theme.colorScheme.onSurface.withValues(alpha: dimmedAlpha)
                  : theme.colorScheme.onSurface,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 12,
                height: 1.35,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: isDimmed ? dimmedAlpha : 1,
                ),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (widget.isCurrent && widget.remainingMinutes != null) ...[
            const SizedBox(height: AppSpacing.space8),
            Text(
              l10n.timelineRemainingMinutes(widget.remainingMinutes!),
              style: TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (widget.isCurrent && widget.onNavigate != null) ...[
            const SizedBox(height: AppSpacing.space8),
            TextButton.icon(
              onPressed: widget.onNavigate,
              icon: const Icon(Icons.navigation_outlined, size: 16),
              label: Text(
                l10n.timelineNavigate,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                foregroundColor: accent,
              ),
            ),
          ],
          if (!widget.isCurrent &&
              widget.onNavigate != null &&
              widget.activity.location != null &&
              widget.activity.location!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            InkWell(
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
                      fontFamily: FontFamily.dMSans,
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
    );

    if (widget.isCurrent) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
        decoration: BoxDecoration(
          borderRadius: AppRadius.large24,
          border: Border.fromBorderSide(timelineCardBorderSide),
          boxShadow: timelineCardBoxShadows,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.large24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const ColoredBox(
                color: timelineNowAccent,
                child: SizedBox(height: 3, width: double.infinity),
              ),
              ColoredBox(color: ColorName.surface, child: inner),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large24,
        border: Border.fromBorderSide(timelineCardBorderSide),
        boxShadow: timelineCardBoxShadows,
      ),
      child: inner,
    );
  }

  Widget _timeCapsule(String label, Color accent, bool isDimmed) {
    final filled = widget.isCurrent;
    if (widget.isCurrent && _pulseOpacity != null) {
      return AnimatedBuilder(
        animation: _pulseOpacity!,
        builder: (context, child) => Opacity(
          opacity: _pulseOpacity!.value,
          child: _capsuleDecoration(
            label: label,
            accent: accent,
            filled: filled,
          ),
        ),
      );
    }
    return _capsuleDecoration(label: label, accent: accent, filled: filled);
  }

  Widget _capsuleDecoration({
    required String label,
    required Color accent,
    required bool filled,
  }) {
    final r = timelineActivityLeadingSize / 2;
    return Container(
      height: timelineActivityLeadingSize,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? accent : timelineCapsuleBackground(accent),
        borderRadius: BorderRadius.circular(r),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: filled ? Colors.white : accent,
          letterSpacing: filled ? 0.35 : 0.15,
        ),
      ),
    );
  }

  Widget _iconCircle(ThemeData theme, Color accent, bool isDimmed) {
    final a = isDimmed ? accent.withValues(alpha: 0.55) : accent;
    final s = timelineActivityLeadingSize;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: timelineIconCircleBackground(a),
      ),
      alignment: Alignment.center,
      child: Icon(widget.activity.category.icon, size: 16, color: a),
    );
  }

  Widget _buildDot(bool isDimmed) {
    if (widget.isCurrent && _pulseScale != null) {
      return SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseScale!,
              builder: (context, child) => Transform.scale(
                scale: _pulseScale!.value,
                child: Opacity(
                  opacity: (1.0 - (_pulseScale!.value - 1.0) / 0.35).clamp(
                    0.0,
                    1.0,
                  ),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: timelineNowAccent.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: timelineNowAccent,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isNext) {
      final accent = timelineCardAccent(
        activity: widget.activity,
        isNow: false,
      );
      final c = isDimmed ? accent.withValues(alpha: 0.5) : accent;
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      );
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isPast
            ? _timelineGrey.withValues(alpha: 0.35)
            : _timelineGrey.withValues(alpha: 0.55),
        border: Border.all(
          color: _timelineGrey.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
    );
  }
}
