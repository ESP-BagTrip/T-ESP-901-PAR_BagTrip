import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class FareInfoCard extends StatelessWidget {
  const FareInfoCard({super.key});

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
              Icon(Icons.credit_card, color: ColorName.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Informations tarifaires',
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
          // Info Box
          Container(
            padding: AppSpacing.allEdgeInsetSpace16,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDF1), // Light grey/blue from screenshot
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: ColorName.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Émission du billet avant le 23/11/2025',
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          color: ColorName.primary.withValues(alpha: 0.7),
                        ),
                      ),
                      const Text(
                        '4 siège(s) restant(s) à ce tarif',
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: ColorName.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Prices
          _buildPriceRow('Tarif de base', '68.00 €'),
          const SizedBox(height: 8),
          _buildPriceRow('Taxes et frais', '69.83 €'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.black12),
          ),
          _buildPriceRow(
            'Prix total',
            '137.83 EUR',
            isBold: true,
            fontSize: 18,
          ),
          const SizedBox(height: 16),
          // Button
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorName.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Réserver ce vol',
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: fontSize,
            color: ColorName.primary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            fontSize: fontSize,
            color: ColorName.primary,
          ),
        ),
      ],
    );
  }
}
