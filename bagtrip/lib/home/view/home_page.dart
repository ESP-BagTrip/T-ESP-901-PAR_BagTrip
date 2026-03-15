import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/home_view.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => HomeBloc()..add(LoadHome())),
        BlocProvider.value(
          value: context.read<TripManagementBloc>()
            ..add(LoadTripsByStatus(status: 'ongoing'))
            ..add(LoadTripsByStatus(status: 'planned'))
            ..add(LoadTripsByStatus(status: 'completed')),
        ),
      ],
      child: const HomeView(),
    );
  }
}
