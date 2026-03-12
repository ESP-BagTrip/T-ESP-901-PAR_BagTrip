import 'package:bagtrip/create_trip_ai/bloc/create_trip_ai_bloc.dart';
import 'package:bagtrip/create_trip_ai/view/create_trip_ai_recap_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateTripAiRecapPage extends StatelessWidget {
  const CreateTripAiRecapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateTripAiBloc()..add(CreateTripAiLoadRecap()),
      child: const CreateTripAiRecapView(),
    );
  }
}
