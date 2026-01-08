import 'package:flutter/material.dart';
import 'package:bagtrip/chat/models/context.dart';
import 'package:bagtrip/chat/widgets/flight_offer_card.dart';
import 'package:bagtrip/chat/widgets/hotel_offer_card.dart';
import 'package:bagtrip/chat/widgets/itinerary_summary.dart';
import 'package:bagtrip/chat/widgets/warning_widget.dart';

/// Widget factory pour rendre les widgets dynamiques selon leur type
class WidgetRenderer extends StatelessWidget {
  final WidgetData widgetData;
  final Function(String actionType, String? offerId)? onAction;

  const WidgetRenderer({super.key, required this.widgetData, this.onAction});

  @override
  Widget build(BuildContext context) {
    switch (widgetData.type) {
      case 'FLIGHT_OFFER_CARD':
        return FlightOfferCard(widgetData: widgetData, onAction: onAction);
      case 'HOTEL_OFFER_CARD':
        return HotelOfferCard(widgetData: widgetData, onAction: onAction);
      case 'ITINERARY_SUMMARY':
        return ItinerarySummary(widgetData: widgetData, onAction: onAction);
      case 'WARNING':
        return WarningWidget(widgetData: widgetData, onAction: onAction);
      default:
        return _UnknownWidget(widgetData: widgetData);
    }
  }
}

/// Widget de fallback pour types inconnus
class _UnknownWidget extends StatelessWidget {
  final WidgetData widgetData;

  const _UnknownWidget({required this.widgetData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Widget inconnu: ${widgetData.type}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (widgetData.title != null) ...[
                const SizedBox(height: 8),
                Text(widgetData.title!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
