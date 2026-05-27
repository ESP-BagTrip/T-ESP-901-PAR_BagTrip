import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Immutable value object representing an inline flight tile.
class ReviewInlineFlightData {
  const ReviewInlineFlightData({
    required this.originIata,
    required this.destinationIata,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationLabel,
    required this.airline,
    required this.priceLabel,
    required this.tagLabel,
  });

  final String originIata;
  final String destinationIata;
  final String departureTime;
  final String arrivalTime;
  final String durationLabel;
  final String airline;
  final String priceLabel;

  /// Editorial tag rendered above the tile ("Outbound", "Return").
  final String tagLabel;
}

/// Refined flight tile — IATA codes in large serif separated by a dashed
/// rule with a plane glyph. No color flash; luxury lives in the restraint.
class ReviewInlineFlight extends StatelessWidget {
  const ReviewInlineFlight({super.key, required this.data});

  final ReviewInlineFlightData data;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final ink = AppColors.reviewInkOf(brightness);
    final cardSurface = AppColors.reviewCardSurfaceOf(brightness);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: AppRadius.large16,
        border: Border.all(
          color: AppColors.reviewCardBorderOf(brightness),
          width: 0.5,
        ),
        boxShadow: AppColors.reviewCardShadowOf(brightness),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space16,
          AppSpacing.space16,
          AppSpacing.space16,
          AppSpacing.space12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.tagLabel.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.flight_takeoff_rounded,
                    size: 12,
                    color: ink.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    data.tagLabel.toUpperCase(),
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                      color: ink.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.space16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _IataBlock(
                  code: data.originIata,
                  time: data.departureTime,
                  ink: ink,
                ),
                const SizedBox(width: AppSpacing.space16),
                Expanded(
                  child: _DashedPath(
                    label: data.durationLabel,
                    ink: ink,
                    cardSurface: cardSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.space16),
                _IataBlock(
                  code: data.destinationIata,
                  time: data.arrivalTime,
                  alignRight: true,
                  ink: ink,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space16),
            Container(
              height: 0.5,
              color: AppColors.reviewDividerFaintOf(brightness),
            ),
            const SizedBox(height: AppSpacing.space8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.airline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.reviewSubtleOf(brightness),
                    ),
                  ),
                ),
                if (data.priceLabel.isNotEmpty)
                  Text(
                    data.priceLabel,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: ink,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IataBlock extends StatelessWidget {
  const _IataBlock({
    required this.code,
    required this.time,
    required this.ink,
    this.alignRight = false,
  });

  final String code;
  final String time;
  final Color ink;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          code.isEmpty ? '—' : code,
          style: TextStyle(
            fontFamily: FontFamily.dMSerifDisplay,
            fontSize: 32,
            height: 1,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
            color: ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          time.isEmpty ? '--:--' : time,
          style: TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: ink.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _DashedPath extends StatelessWidget {
  const _DashedPath({
    required this.label,
    required this.ink,
    required this.cardSurface,
  });

  final String label;
  final Color ink;
  final Color cardSurface;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: ink.withValues(alpha: 0.4),
              ),
            ),
          ),
        SizedBox(
          height: 18,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, 1),
                  painter: _DashPainter(ink: ink.withValues(alpha: 0.22)),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: cardSurface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.flight_rounded,
                    size: 13,
                    color: ink.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.ink});

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    const dashWidth = 3.5;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dashWidth, size.height / 2),
        paint,
      );
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) =>
      oldDelegate.ink != ink;
}
