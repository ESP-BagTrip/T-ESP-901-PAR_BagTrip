import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
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

/// Graphic inline flight tile — airline ticket vibe with IATA codes, a
/// dashed travel path and a plane glyph riding it. Colored accent strip
/// at the top marks the tile as a transit event in the day's narrative.
class ReviewInlineFlight extends StatelessWidget {
  const ReviewInlineFlight({super.key, required this.data});

  final ReviewInlineFlightData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: AppRadius.large16,
        border: Border.all(color: AppColors.reviewBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorName.primary, ColorName.primaryDark],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.cornerRaidus16),
                topRight: Radius.circular(AppRadius.cornerRaidus16),
              ),
            ),
          ),
          Padding(
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ColorName.primary.withValues(alpha: 0.12),
                          borderRadius: AppRadius.pill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.flight_takeoff_rounded,
                              size: 12,
                              color: ColorName.primaryDark,
                            ),
                            const SizedBox(width: AppSpacing.space4),
                            Text(
                              data.tagLabel.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: FontFamily.b612,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: ColorName.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.space12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _IataBlock(code: data.originIata, time: data.departureTime),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(child: _DashedPath(label: data.durationLabel)),
                    const SizedBox(width: AppSpacing.space12),
                    _IataBlock(
                      code: data.destinationIata,
                      time: data.arrivalTime,
                      alignRight: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space12),
                Container(height: 1, color: AppColors.reviewDividerFaint),
                const SizedBox(height: AppSpacing.space8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.airline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.reviewSubtle,
                        ),
                      ),
                    ),
                    if (data.priceLabel.isNotEmpty)
                      Text(
                        data.priceLabel,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.reviewInk,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IataBlock extends StatelessWidget {
  const _IataBlock({
    required this.code,
    required this.time,
    this.alignRight = false,
  });

  final String code;
  final String time;
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
          style: const TextStyle(
            fontFamily: FontFamily.dMSerifDisplay,
            fontSize: 30,
            height: 1,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
            color: ColorName.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time.isEmpty ? '--:--' : time,
          style: const TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.reviewSubtle,
          ),
        ),
      ],
    );
  }
}

class _DashedPath extends StatelessWidget {
  const _DashedPath({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space4),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.reviewFaint,
              ),
            ),
          ),
        SizedBox(
          height: 20,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, 2),
                  painter: _DashPainter(),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorName.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.flight_rounded,
                    size: 14,
                    color: ColorName.primaryDark,
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ColorName.primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dashWidth = 4.0;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
