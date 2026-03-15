import 'package:bagtrip/design/widgets/status_badge.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter/material.dart';

class TripStatusBadge extends StatelessWidget {
  final TripStatus status;

  const TripStatusBadge({super.key, required this.status});

  StatusType _mapStatus() {
    return switch (status) {
      TripStatus.ongoing => StatusType.active,
      TripStatus.planned || TripStatus.draft => StatusType.forecasted,
      TripStatus.completed => StatusType.completed,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StatusBadge(type: _mapStatus());
  }
}
