import 'package:bagtrip/models/trip_home.dart' as models;
import 'package:flutter/material.dart';

class TripFeatureTileWidget extends StatelessWidget {
  final models.TripFeatureTile feature;
  final VoidCallback? onTap;

  const TripFeatureTileWidget({super.key, required this.feature, this.onTap});

  IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'luggage':
        return Icons.luggage;
      case 'wallet':
        return Icons.wallet;
      case 'hotel':
        return Icons.hotel;
      case 'hiking':
        return Icons.hiking;
      case 'directions_car':
        return Icons.directions_car;
      case 'map':
        return Icons.map;
      default:
        return Icons.extension;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = feature.enabled;

    return Card(
      elevation: isEnabled ? 1 : 0,
      color: isEnabled
          ? null
          : Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconFromString(feature.icon),
                size: 32,
                color: isEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                feature.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isEnabled
                      ? null
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (!isEnabled) ...[
                const SizedBox(height: 4),
                Text(
                  'Bientôt',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
