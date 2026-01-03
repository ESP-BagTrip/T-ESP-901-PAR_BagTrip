import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class BaggageInfoCard extends StatelessWidget {
  const BaggageInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorName.primarySoftLight,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: AppSpacing.allEdgeInsetSpace16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.luggage, color: ColorName.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Bagages inclus',
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: ColorName.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cabin Baggage
          _buildBaggageRow(
            icon: Icons.work_outline,
            title: 'Bagage cabine',
            subtitle: '2 bagage(s) cabine inclus',
            subtitleColor: ColorName.secondary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.black12),
          ),
          // Checked Baggage
          _buildBaggageRow(
            icon: Icons.luggage_outlined,
            title: 'Bagage en soute',
            subtitle: '1 bagage de 25KG inclus',
            subtitleColor: ColorName.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBaggageRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ColorName.primary, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                color: ColorName.primary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
