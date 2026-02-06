import 'package:bagtrip/chat/models/context.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class ItinerarySummary extends StatelessWidget {
  final WidgetData widgetData;
  final Function(String actionType, String? offerId)? onAction;

  const ItinerarySummary({super.key, required this.widgetData, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: ColorName.infoLight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorName.infoLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map,
                      color: ColorName.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widgetData.title ?? 'Résumé de l\'itinéraire',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Contenu depuis data
              if (widgetData.data != null) ...[
                _buildItineraryContent(widgetData.data!),
              ],

              // Actions
              if (widgetData.actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      widgetData.actions.map((action) {
                        return ElevatedButton(
                          onPressed: () {
                            onAction?.call(action.type, widgetData.offerId);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            backgroundColor: ColorName.info,
                            foregroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(action.label),
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItineraryContent(Map<String, dynamic> data) {
    final List<Widget> items = [];

    if (data['flight'] != null) {
      items.add(
        _buildItineraryItem(
          Icons.flight_takeoff,
          'Vol',
          data['flight'] as String,
        ),
      );
    }

    if (data['hotel'] != null) {
      items.add(
        _buildItineraryItem(Icons.hotel, 'Hôtel', data['hotel'] as String),
      );
    }

    if (data['total_price'] != null) {
      items.add(
        _buildItineraryItem(
          Icons.euro,
          'Prix total',
          data['total_price'] as String,
          isHighlight: true,
        ),
      );
    }

    return Column(children: items);
  }

  Widget _buildItineraryItem(
    IconData icon,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ColorName.info),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.hint,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? ColorName.info : AppColors.primaryTrueDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
