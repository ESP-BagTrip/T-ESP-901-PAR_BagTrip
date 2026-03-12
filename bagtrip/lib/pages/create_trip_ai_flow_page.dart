import 'package:bagtrip/create_trip_ai/bloc/create_trip_ai_bloc.dart';
import 'package:bagtrip/create_trip_ai/view/create_trip_ai_recap_view.dart';
import 'package:bagtrip/create_trip_ai/view/create_trip_ai_results_view.dart';
import 'package:bagtrip/create_trip_ai/view/create_trip_ai_summary_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Single entry for the Create Trip AI flow. Provides the bloc and shows
/// Recap, Results, or Summary based on state (no route push between steps).
class CreateTripAiFlowPage extends StatelessWidget {
  const CreateTripAiFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateTripAiBloc()..add(CreateTripAiLoadRecap()),
      child: BlocBuilder<CreateTripAiBloc, CreateTripAiState>(
        builder: (context, state) {
          if (state is CreateTripAiRecapLoaded ||
              state is CreateTripAiRecapLoading ||
              state is CreateTripAiInitial) {
            return const CreateTripAiRecapView();
          }
          if (state is CreateTripAiResultsLoaded) {
            return const CreateTripAiResultsView();
          }
          if (state is CreateTripAiSummaryLoaded) {
            return const CreateTripAiSummaryView();
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
