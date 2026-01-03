import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class ClassInfoCard extends StatelessWidget {
  const ClassInfoCard({super.key});

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
              Icon(Icons.people_outline, color: ColorName.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Classe et conditions',
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
          // Info Rows
          _buildInfoRow('Classe de réservation', 'D', ColorName.secondary),
          const SizedBox(height: 8),
          _buildInfoRow('Cabine', 'Économique', ColorName.secondary),
          const SizedBox(height: 8),
          _buildInfoRow('Code tarifaire', 'DROPLVY', ColorName.secondary),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 14,
            color: ColorName.primary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
