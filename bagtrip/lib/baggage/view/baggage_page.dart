import 'package:bagtrip/baggage/bloc/baggage_bloc.dart';
import 'package:bagtrip/baggage/view/baggage_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BaggageBlocPage extends StatelessWidget {
  final String tripId;
  final String role;
  final bool isCompleted;

  const BaggageBlocPage({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BaggageBloc()..add(LoadBaggage(tripId: tripId)),
      child: BaggageView(tripId: tripId, role: role, isCompleted: isCompleted),
    );
  }
}
