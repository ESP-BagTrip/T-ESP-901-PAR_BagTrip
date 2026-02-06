import 'package:bagtrip/chat/models/context.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class HotelOfferCard extends StatelessWidget {
  final WidgetData widgetData;
  final Function(String actionType, String? offerId)? onAction;

  const HotelOfferCard({super.key, required this.widgetData, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec icône
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorName.warningLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.hotel,
                        color: ColorName.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widgetData.title != null)
                            Text(
                              widgetData.title!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (widgetData.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widgetData.subtitle!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.hint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Informations supplémentaires depuis data
                if (widgetData.data != null) ...[
                  const SizedBox(height: 12),
                  _buildDataInfo(widgetData.data!),
                ],

                const Spacer(),

                // Actions
                if (widgetData.actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        widgetData.actions.map((action) {
                          return _buildActionButton(context, action);
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataInfo(Map<String, dynamic> data) {
    final List<Widget> infoWidgets = [];

    if (data['address'] != null) {
      infoWidgets.add(
        _buildInfoRow(Icons.location_on, 'Adresse', data['address'] as String),
      );
    }

    if (data['rating'] != null) {
      infoWidgets.add(_buildInfoRow(Icons.star, 'Note', '${data['rating']}/5'));
    }

    if (data['stars'] != null) {
      infoWidgets.add(
        _buildInfoRow(Icons.hotel, 'Étoiles', '${data['stars']} étoiles'),
      );
    }

    if (data['amenities'] != null) {
      final amenities = data['amenities'] as List<dynamic>?;
      if (amenities != null && amenities.isNotEmpty) {
        infoWidgets.add(
          _buildInfoRow(
            Icons.check_circle,
            'Services',
            amenities.take(3).join(', '),
          ),
        );
      }
    }

    return Column(children: infoWidgets);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.hint),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: AppColors.hint),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetAction action) {
    final isPrimary = action.type.contains('BOOK');

    return ElevatedButton(
      onPressed: () {
        onAction?.call(action.type, widgetData.offerId);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        backgroundColor:
            isPrimary ? Theme.of(context).primaryColor : AppColors.border,
        foregroundColor:
            isPrimary ? AppColors.surface : AppColors.primaryTrueDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: isPrimary ? 2 : 0,
      ),
      child: Text(
        action.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
