import 'package:bagtrip/trips/bloc/trip_share_bloc.dart';
import 'package:bagtrip/trips/view/trip_shares_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripSharesPage extends StatelessWidget {
  final String tripId;

  const TripSharesPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TripShareBloc()..add(LoadShares(tripId: tripId)),
      child: TripSharesView(tripId: tripId),
    );
  }
}
