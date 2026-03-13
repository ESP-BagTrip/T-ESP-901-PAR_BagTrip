import 'package:bagtrip/models/trip.dart';
import 'package:flutter/material.dart';

class TripStatusBadge extends StatelessWidget {
  final TripStatus status;

  const TripStatusBadge({super.key, required this.status});

  Color _backgroundColor() {
    switch (status) {
      case TripStatus.ongoing:
        return const Color(0xFF4CAF50);
      case TripStatus.planned:
      case TripStatus.draft:
        return const Color(0xFF2196F3);
      case TripStatus.completed:
        return const Color(0xFF9E9E9E);
    }
  }

  String _label() {
    switch (status) {
      case TripStatus.ongoing:
        return 'En cours';
      case TripStatus.planned:
      case TripStatus.draft:
        return 'Planifié';
      case TripStatus.completed:
        return 'Terminé';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          color: _backgroundColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
