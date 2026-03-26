import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/home_view.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeBloc = context.read<HomeBloc>();
    if (homeBloc.state is HomeInitial) {
      homeBloc.add(LoadHome());
      for (final s in ['ongoing', 'planned', 'completed']) {
        context.read<TripManagementBloc>().add(LoadTripsByStatus(status: s));
      }
    }
    return const HomeView();
  }
}
