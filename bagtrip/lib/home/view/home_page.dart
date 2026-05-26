import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/home_view.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final homeBloc = context.read<HomeBloc>();
      if (homeBloc.state is HomeInitial) {
        homeBloc.add(LoadHome());
        for (final s in ['ongoing', 'planned', 'completed']) {
          context.read<TripManagementBloc>().add(LoadTripsByStatus(status: s));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}
