import 'package:bagtrip/home/bloc/home_flight_bloc.dart';
import 'package:bagtrip/home/view/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => HomeFlightBloc(),
        child: const SafeArea(left: false, right: false, child: HomeView()),
      ),
    );
  }
}
