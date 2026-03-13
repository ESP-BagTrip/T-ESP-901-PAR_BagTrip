import 'package:bagtrip/activities/bloc/activity_bloc.dart';
import 'package:bagtrip/activities/view/activities_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActivitiesPage extends StatelessWidget {
  final String tripId;
  final String role;

  const ActivitiesPage({super.key, required this.tripId, this.role = 'OWNER'});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActivityBloc()..add(LoadActivities(tripId: tripId)),
      child: ActivitiesView(tripId: tripId, role: role),
    );
  }
}
