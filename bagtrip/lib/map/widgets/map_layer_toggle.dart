import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/map/bloc/map_bloc.dart';
import 'package:flutter/material.dart';

class MapLayerToggle extends StatelessWidget {
  final MapLayerType activeLayer;
  final ValueChanged<MapLayerType> onLayerChanged;

  const MapLayerToggle({
    super.key,
    required this.activeLayer,
    required this.onLayerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium8,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LayerButton(
            icon: Icons.local_airport,
            label: 'Airports',
            isActive: activeLayer == MapLayerType.airports,
            activeColor: ColorName.primary,
            onTap: () => onLayerChanged(MapLayerType.airports),
            isFirst: true,
          ),
          Container(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          _LayerButton(
            icon: Icons.hotel,
            label: 'Hotels',
            isActive: activeLayer == MapLayerType.hotels,
            activeColor: ColorName.secondary,
            onTap: () => onLayerChanged(MapLayerType.hotels),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _LayerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _LayerButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? const Radius.circular(AppRadius.cornerRaidus8) : Radius.zero,
        topRight: isFirst ? const Radius.circular(AppRadius.cornerRaidus8) : Radius.zero,
        bottomLeft: isLast ? const Radius.circular(AppRadius.cornerRaidus8) : Radius.zero,
        bottomRight: isLast ? const Radius.circular(AppRadius.cornerRaidus8) : Radius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(AppRadius.cornerRaidus8) : Radius.zero,
          topRight: isFirst ? const Radius.circular(AppRadius.cornerRaidus8) : Radius.zero,
          bottomLeft: isLast ? const Radius.circular(AppRadius.cornerRaidus8) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(AppRadius.cornerRaidus8) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? activeColor : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : Colors.grey[600],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
