import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:flutter/material.dart';

/// Landing panel for the trip-detail screen. Instead of summarising what's
/// *in* the trip (old OverviewPanel), it surfaces what's left for the user to
/// validate — one row per domain, the overall score on top, and a tap
/// shortcut to each domain's dedicated chip.
class ValidationBoardPanel extends StatelessWidget {
  const ValidationBoardPanel({
    super.key,
    required this.state,
    required this.onJumpToTab,
  });

  final TripDetailLoaded state;
  final ValueChanged<int> onJumpToTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = state.completionResult;

    final rows = <_BoardRow>[
      _BoardRow(
        icon: Icons.flight_takeoff_rounded,
        label: l10n.reviewTabFlights,
        segment: result.segment(CompletionSegmentType.flights),
        tabIndex: 1,
      ),
      _BoardRow(
        icon: Icons.hotel_rounded,
        label: l10n.reviewTabHotel,
        segment: result.segment(CompletionSegmentType.accommodation),
        tabIndex: 2,
      ),
      _BoardRow(
        icon: Icons.hiking_rounded,
        label: l10n.reviewTabItinerary,
        segment: result.segment(CompletionSegmentType.activities),
        tabIndex: 3,
      ),
      _BoardRow(
        icon: Icons.luggage_rounded,
        label: l10n.reviewTabEssentials,
        segment: result.segment(CompletionSegmentType.baggage),
        tabIndex: 4,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space24,
        AppSpacing.space16,
        AppSpacing.space40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OverallHeader(percentage: result.percentage, l10n: l10n),
          const SizedBox(height: AppSpacing.space24),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFBFAF7),
              borderRadius: AppRadius.large24,
              border: Border.all(
                color: const Color(0xFF0D1F35).withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  _BoardRowTile(
                    row: rows[i],
                    onTap: () => onJumpToTab(rows[i].tabIndex),
                    l10n: l10n,
                  ),
                  if (i < rows.length - 1)
                    const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: AppSpacing.space24,
                      endIndent: AppSpacing.space24,
                      color: AppColors.reviewDividerFaint,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardRow {
  const _BoardRow({
    required this.icon,
    required this.label,
    required this.segment,
    required this.tabIndex,
  });

  final IconData icon;
  final String label;
  final CompletionSegment segment;
  final int tabIndex;
}

class _OverallHeader extends StatelessWidget {
  const _OverallHeader({required this.percentage, required this.l10n});

  final int percentage;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.validationBoardEyebrow.toUpperCase(),
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.2,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$percentage',
              style: const TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 72,
                height: 1,
                fontWeight: FontWeight.w400,
                letterSpacing: -3,
                color: AppColors.reviewInk,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 14, left: 4),
              child: Text(
                '%',
                style: TextStyle(
                  fontFamily: FontFamily.dMSerifDisplay,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: AppColors.reviewInk,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          l10n.validationBoardSubtitle,
          style: TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 13,
            color: AppColors.reviewInk.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _BoardRowTile extends StatelessWidget {
  const _BoardRowTile({
    required this.row,
    required this.onTap,
    required this.l10n,
  });

  final _BoardRow row;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final state = _statusCopy();
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.large24,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space24,
          vertical: AppSpacing.space16,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: state.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(row.icon, size: 18, color: state.accent),
            ),
            const SizedBox(width: AppSpacing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                      color: AppColors.reviewInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.label,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      letterSpacing: 0.2,
                      color: state.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.reviewInk.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }

  _RowStatus _statusCopy() {
    final segment = row.segment;
    if (segment.isSkipped) {
      return _RowStatus(
        label: l10n.validationBoardStatusSkipped,
        accent: AppColors.reviewMuted,
      );
    }
    if (segment.total == 0) {
      return _RowStatus(
        label: l10n.validationBoardStatusNothing,
        accent: AppColors.reviewMuted,
      );
    }
    if (segment.isComplete) {
      return _RowStatus(
        label: l10n.validationBoardStatusAllDone,
        accent: ColorName.secondary,
      );
    }
    final remaining = segment.total - segment.done;
    return _RowStatus(
      label: l10n.validationBoardStatusRemaining(remaining, segment.total),
      accent: ColorName.primary,
    );
  }
}

class _RowStatus {
  const _RowStatus({required this.label, required this.accent});

  final String label;
  final Color accent;
}
