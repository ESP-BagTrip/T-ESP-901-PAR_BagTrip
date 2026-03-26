import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class FlightStatusBadge extends StatelessWidget {
  final String status;
  final int? delay;

  const FlightStatusBadge({super.key, required this.status, this.delay});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusConfig(status, delay);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _statusConfig(String status, int? delay) {
    return switch (status.toLowerCase()) {
      'scheduled' => (AppColors.hint, 'Scheduled'),
      'active' || 'en-route' => (ColorName.success, 'On time'),
      'landed' => (ColorName.info, 'Landed'),
      'cancelled' => (ColorName.error, 'Cancelled'),
      'incident' || 'diverted' => (ColorName.error, 'Incident'),
      _ when delay != null && delay > 0 => (
        ColorName.warning,
        'Delayed +${delay}min',
      ),
      _ => (ColorName.success, 'On time'),
    };
  }
}
