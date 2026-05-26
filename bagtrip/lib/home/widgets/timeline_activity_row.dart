import 'package:bagtrip/design/app_colors.dart';
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

  /// When set (e.g. Terminé / Maintenant / Ensuite), replaces time in the capsule.
  final String? capsuleScheduleBadge;

  /// Past completed items (full day or ended slot): strikethrough + dimming.
  final bool strikeThroughTitle;

  /// Opacity for dimmed text; default 0.55, use 0.65 for schedule v3 past items.
  final double? contentDimAlpha;

  /// When true, skips the timeline rail and the bordered surface/shadow card
  /// (pill + icon + text only — e.g. active trip hero bottom strip).
  final bool bare;

  /// Programme screen: "Maintenant" capsules use [ColorName.secondary], others
  /// use [ColorName.primaryDark]. Home hero (`bare: true`) must leave this false.
  final bool useProgrammeCapsuleColors;

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
    this.capsuleScheduleBadge,
    this.strikeThroughTitle = false,
    this.contentDimAlpha,
    this.bare = false,
    this.useProgrammeCapsuleColors = false,
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
    if (widget.useProgrammeCapsuleColors) {
      final base = widget.isCurrent
          ? ColorName.secondary
          : ColorName.primaryDark;
      return isDimmed ? base.withValues(alpha: 0.5) : base;
    }
    final base = timelineCardAccent(
      activity: widget.activity,
      isNow: widget.isCurrent,
    );
    return isDimmed ? base.withValues(alpha: 0.5) : base;
  }

  Color get _nowStripeColor => widget.useProgrammeCapsuleColors
      ? ColorName.secondary
      : timelineNowAccent;

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
    final dimmedAlpha =
        widget.contentDimAlpha ?? (widget.strikeThroughTitle ? 0.65 : 0.55);
    final isDimmed =
        widget.strikeThroughTitle ||
        (widget.isPast && !widget.isCurrent && !widget.isNext);

    if (widget.bare) {
      return _buildCardShell(
        theme: theme,
        l10n: l10n,
        isDimmed: isDimmed,
        dimmedAlpha: dimmedAlpha,
        bare: true,
      );
    }

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
              bare: false,
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
    required bool bare,
  }) {
    final accent = _accent(isDimmed);
    final capsuleLabel =
        widget.capsuleScheduleBadge ??
        (widget.isCurrent
            ? l10n.homeSectionNowBadge
            : (widget.activity.startTime ?? l10n.activeTripsAllDay));
    final subtitle = _subtitleLine(l10n);

    final inner = Padding(
      padding: bare
          ? EdgeInsets.zero
          : const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _timeCapsule(capsuleLabel, accent, isDimmed, theme),
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
              decoration: widget.strikeThroughTitle
                  ? TextDecoration.lineThrough
                  : null,
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

    if (bare) {
      return inner;
    }

    final cardColor = _cardBackgroundColor(theme);
    final cardBorder = _cardBorderSide(theme);
    final cardShadows = _cardBoxShadows(theme);

    if (widget.isCurrent) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
        decoration: BoxDecoration(
          borderRadius: AppRadius.large24,
          border: Border.fromBorderSide(cardBorder),
          boxShadow: cardShadows,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.large24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ColoredBox(
                color: _nowStripeColor,
                child: const SizedBox(height: 3, width: double.infinity),
              ),
              ColoredBox(color: cardColor, child: inner),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.large24,
        border: Border.fromBorderSide(cardBorder),
        boxShadow: cardShadows,
      ),
      child: inner,
    );
  }

  Color _cardBackgroundColor(ThemeData theme) {
    if (widget.useProgrammeCapsuleColors) {
      return AppColors.surfaceGroupOf(theme.brightness);
    }
    return ColorName.surface;
  }

  BorderSide _cardBorderSide(ThemeData theme) {
    if (widget.useProgrammeCapsuleColors) {
      return BorderSide(
        color: AppColors.surfaceGroupBorderOf(theme.brightness),
      );
    }
    return timelineCardBorderSide;
  }

  List<BoxShadow>? _cardBoxShadows(ThemeData theme) {
    if (widget.useProgrammeCapsuleColors &&
        theme.brightness == Brightness.dark) {
      return null;
    }
    return timelineCardBoxShadows;
  }

  bool get _capsuleFilled =>
      widget.isCurrent || widget.useProgrammeCapsuleColors;

  Color _capsuleBackgroundColor(Color accent, bool filled) {
    if (widget.useProgrammeCapsuleColors) return accent;
    return filled ? accent : timelineCapsuleBackground(accent);
  }

  Color _capsuleForegroundColor(Color accent, bool filled) {
    if (widget.useProgrammeCapsuleColors) return Colors.white;
    return filled ? Colors.white : accent;
  }

  bool _programmeOutlinedCapsule(ThemeData theme) =>
      widget.useProgrammeCapsuleColors &&
      !widget.isCurrent &&
      theme.brightness == Brightness.dark;

  /// Frosted pill on dark surfaces — same treatment as [ActiveTripWeatherCard].
  static const Color _programmeGlassTint = Colors.white;

  Widget _timeCapsule(
    String label,
    Color accent,
    bool isDimmed,
    ThemeData theme,
  ) {
    final filled = _capsuleFilled;
    if (widget.isCurrent && _pulseOpacity != null) {
      return AnimatedBuilder(
        animation: _pulseOpacity!,
        builder: (context, child) => Opacity(
          opacity: _pulseOpacity!.value,
          child: _capsuleDecoration(
            label: label,
            accent: accent,
            filled: filled,
            theme: theme,
            isDimmed: isDimmed,
          ),
        ),
      );
    }
    return _capsuleDecoration(
      label: label,
      accent: accent,
      filled: filled,
      theme: theme,
      isDimmed: isDimmed,
    );
  }

  Widget _capsuleDecoration({
    required String label,
    required Color accent,
    required bool filled,
    required ThemeData theme,
    required bool isDimmed,
  }) {
    final outlined = _programmeOutlinedCapsule(theme);
    final dimmedAlpha =
        widget.contentDimAlpha ?? (widget.strikeThroughTitle ? 0.65 : 0.55);
    final baseForeground = outlined
        ? _programmeGlassTint
        : _capsuleForegroundColor(accent, filled);
    final foreground = isDimmed
        ? baseForeground.withValues(alpha: dimmedAlpha)
        : baseForeground;
    final background = outlined
        ? _programmeGlassTint.withValues(alpha: isDimmed ? 0.12 : 0.22)
        : _capsuleBackgroundColor(accent, filled);
    final border = outlined
        ? Border.all(
            color: _programmeGlassTint.withValues(
              alpha: isDimmed ? 0.18 : 0.28,
            ),
          )
        : null;

    final r = timelineActivityLeadingSize / 2;
    return Container(
      height: timelineActivityLeadingSize,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(r),
        border: border,
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
          color: foreground,
          letterSpacing: filled && !outlined ? 0.35 : 0.15,
        ),
      ),
    );
  }

  Widget _iconCircle(ThemeData theme, Color accent, bool isDimmed) {
    final s = timelineActivityLeadingSize;
    if (widget.useProgrammeCapsuleColors) {
      final bg = isDimmed ? accent.withValues(alpha: 0.5) : accent;
      return Container(
        width: s,
        height: s,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        alignment: Alignment.center,
        child: Icon(
          widget.activity.category.icon,
          size: 16,
          color: Colors.white.withValues(alpha: isDimmed ? 0.65 : 1),
        ),
      );
    }
    final a = isDimmed ? accent.withValues(alpha: 0.55) : accent;
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
                        color: _nowStripeColor.withValues(alpha: 0.4),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _nowStripeColor,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isNext) {
      final accent = widget.useProgrammeCapsuleColors
          ? ColorName.primaryDark
          : timelineCardAccent(activity: widget.activity, isNow: false);
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
