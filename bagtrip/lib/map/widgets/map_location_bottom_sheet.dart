import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class MapLocationBottomSheet extends StatelessWidget {
  final Map<String, dynamic> location;
  final VoidCallback onClose;

  const MapLocationBottomSheet({
    super.key,
    required this.location,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final name = location['name']?.toString() ?? 'Unknown Airport';
    final iataCode = location['iataCode']?.toString() ?? '';
    final city = location['city']?.toString() ?? location['cityName']?.toString() ?? '';
    final countryCode = location['countryCode']?.toString() ?? '';
    final countryName = location['countryName']?.toString() ?? '';

    return Padding(
      padding: AppSpacing.allEdgeInsetSpace16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorName.primaryDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Row(
                      children: [
                        if (iataCode.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColorName.primary.withValues(alpha: 0.1),
                              borderRadius: AppRadius.small4,
                            ),
                            child: Text(
                              iataCode,
                              style: const TextStyle(
                                color: ColorName.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (iataCode.isNotEmpty && city.isNotEmpty)
                          const SizedBox(width: AppSpacing.space8),
                        if (city.isNotEmpty)
                          Expanded(
                            child: Text(
                              city,
                              style: const TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                color: Colors.grey,
              ),
            ],
          ),

          // Country info
          if (countryName.isNotEmpty || countryCode.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  countryName.isNotEmpty ? countryName : countryCode,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.space24),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                onClose();
                // TODO: Navigate to flight search with this airport
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorName.primary,
                foregroundColor: Colors.white,
                padding: AppSpacing.verticalSpace16,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.large16,
                ),
              ),
              icon: const Icon(Icons.flight_takeoff),
              label: const Text(
                'Search Flights from here',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Safe area padding for bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
