import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FareInfoCard extends StatelessWidget {
  final double price;
  final double basePrice;
  final int numberOfBookableSeats;
  final String lastTicketingDate;
  final VoidCallback? onPressed;

  const FareInfoCard({
    super.key,
    required this.price,
    required this.basePrice,
    required this.numberOfBookableSeats,
    required this.lastTicketingDate,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate taxes
    final taxes = price - basePrice;

    return Container(
      decoration: BoxDecoration(
        color: ColorName.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: AppSpacing.allEdgeInsetSpace16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.credit_card,
                color: ColorName.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.fareInformation,
                style: const TextStyle(
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
                        AppLocalizations.of(
                          context,
                        )!.ticketEmissionDeadline(lastTicketingDate),
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          color: ColorName.primary.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.seatsRemaining(numberOfBookableSeats),
                        style: const TextStyle(
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
          _buildPriceRow(
            AppLocalizations.of(context)!.baseFare,
            '${basePrice.toStringAsFixed(2)} €',
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            AppLocalizations.of(context)!.taxesAndFees,
            '${taxes.toStringAsFixed(2)} €',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.black12),
          ),
          _buildPriceRow(
            AppLocalizations.of(context)!.totalPrice,
            '${price.toStringAsFixed(2)} €',
            isBold: true,
            fontSize: 18,
          ),
          const SizedBox(height: 16),
          // Button
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorName.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.bookThisFlight,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
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
