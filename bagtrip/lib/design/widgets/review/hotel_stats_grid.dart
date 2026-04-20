import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// A single stat box inside [HotelStatsGrid].
class HotelStatBox extends StatelessWidget {
  const HotelStatBox({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: const BoxDecoration(
        color: ColorName.surfaceLight,
        borderRadius: AppRadius.large16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: ColorName.hint,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorName.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// A 2×2 grid of [HotelStatBox] tiles. Used to expose key facts about an
/// accommodation (check-in, check-out, nights, price/night…).
///
/// Expects exactly 4 entries; renders nothing otherwise.
class HotelStatsGrid extends StatelessWidget {
  const HotelStatsGrid({super.key, required this.entries});

  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 4) {
      return const SizedBox.shrink();
    }
    final firstRow = entries.take(2).toList(growable: false);
    final secondRow = entries.skip(2).take(2).toList(growable: false);
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: HotelStatBox(
                  label: firstRow[0].$1,
                  value: firstRow[0].$2,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: HotelStatBox(
                  label: firstRow[1].$1,
                  value: firstRow[1].$2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: HotelStatBox(
                  label: secondRow[0].$1,
                  value: secondRow[0].$2,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: HotelStatBox(
                  label: secondRow[1].$1,
                  value: secondRow[1].$2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
