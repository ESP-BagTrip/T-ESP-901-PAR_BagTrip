import 'package:bagtrip/transports/bloc/transport_bloc.dart';
import 'package:bagtrip/transports/view/transports_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransportsPage extends StatelessWidget {
  final String tripId;
  final String role;
  final bool isCompleted;

  const TransportsPage({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransportBloc()..add(LoadTransports(tripId: tripId)),
      child: TransportsView(
        tripId: tripId,
        role: role,
        isCompleted: isCompleted,
      ),
    );
  }
}
