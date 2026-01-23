import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/service/hotel_service.dart';
import 'package:flutter/material.dart';

class MapHotelBottomSheet extends StatelessWidget {
  final Hotel hotel;
  final VoidCallback onClose;

  const MapHotelBottomSheet({
    super.key,
    required this.hotel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
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
                      hotel.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorName.primaryDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    // Rating stars
                    if (hotel.rating != null)
                      Row(
                        children: [
                          ...List.generate(
                            hotel.rating!.floor(),
                            (index) => const Icon(
                              Icons.star,
                              size: 18,
                              color: Colors.amber,
                            ),
                          ),
                          if (hotel.rating! % 1 >= 0.5)
                            const Icon(
                              Icons.star_half,
                              size: 18,
                              color: Colors.amber,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            hotel.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
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

          // Address
          if (hotel.address != null && hotel.address!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hotel.address!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Price per night
          if (hotel.pricePerNight != null) ...[
            const SizedBox(height: AppSpacing.space16),
            Container(
              padding: AppSpacing.allEdgeInsetSpace16,
              decoration: BoxDecoration(
                color: ColorName.secondary.withValues(alpha: 0.1),
                borderRadius: AppRadius.medium8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Price per night',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${hotel.pricePerNight!.toStringAsFixed(2)} ${hotel.currency ?? 'EUR'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ColorName.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Amenities chips
          if (hotel.amenities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space16),
            const Text(
              'Amenities',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hotel.amenities.take(6).map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: AppRadius.small4,
                  ),
                  child: Text(
                    _formatAmenity(amenity),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: AppSpacing.space24),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                onClose();
                // TODO: Navigate to hotel details/booking
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorName.secondary,
                foregroundColor: Colors.white,
                padding: AppSpacing.verticalSpace16,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.large16,
                ),
              ),
              icon: const Icon(Icons.book_online),
              label: const Text(
                'View Details & Book',
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

  String _formatAmenity(String amenity) {
    // Convert SCREAMING_CASE to Title Case
    return amenity
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
