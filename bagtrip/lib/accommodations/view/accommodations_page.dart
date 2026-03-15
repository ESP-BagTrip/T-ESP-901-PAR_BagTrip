import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/view/accommodations_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccommodationsPage extends StatelessWidget {
  final String tripId;
  final String role;
  final bool isCompleted;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;

  const AccommodationsPage({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
    this.tripStartDate,
    this.tripEndDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AccommodationBloc()..add(LoadAccommodations(tripId: tripId)),
      child: AccommodationsView(
        tripId: tripId,
        role: role,
        isCompleted: isCompleted,
        tripStartDate: tripStartDate,
        tripEndDate: tripEndDate,
      ),
    );
  }
}
