import 'package:bagtrip/map/bloc/map_bloc.dart';
import 'package:bagtrip/map/view/map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MapBloc()
        ..add(LoadNearbyLocations(
          latitude: 48.8566, // Paris default
          longitude: 2.3522,
        )),
      child: const MapView(),
    );
  }
}
