import 'package:bagtrip/create_trip_ai/bloc/create_trip_ai_bloc.dart';
import 'package:bagtrip/create_trip_ai/view/create_trip_ai_recap_view.dart';
import 'package:bagtrip/create_trip_ai/view/create_trip_ai_results_view.dart';
import 'package:bagtrip/create_trip_ai/view/create_trip_ai_summary_view.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Single entry for the Create Trip AI flow. Provides the bloc and shows
/// Recap, Results, or Summary based on state (no route push between steps).
class CreateTripAiFlowPage extends StatelessWidget {
  const CreateTripAiFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateTripAiBloc()..add(CreateTripAiLoadRecap()),
      child: BlocListener<CreateTripAiBloc, CreateTripAiState>(
        listener: (context, state) {
          if (state is CreateTripAiQuotaExceeded) {
            PremiumPaywall.show(context);
            context.read<CreateTripAiBloc>().add(CreateTripAiLoadRecap());
          }
          if (state is CreateTripAiTripCreated) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Voyage créé !')));
            context.go('/trips');
          }
        },
        child: BlocBuilder<CreateTripAiBloc, CreateTripAiState>(
          builder: (context, state) {
            if (state is CreateTripAiRecapLoaded ||
                state is CreateTripAiRecapLoading ||
                state is CreateTripAiInitial) {
              return const CreateTripAiRecapView();
            }
            if (state is CreateTripAiSearchLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is CreateTripAiResultsLoaded) {
              return const CreateTripAiResultsView();
            }
            if (state is CreateTripAiSummaryLoaded ||
                state is CreateTripAiTripCreated) {
              return const CreateTripAiSummaryView();
            }
            if (state is CreateTripAiError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Erreur')),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.read<CreateTripAiBloc>().add(
                            CreateTripAiLoadRecap(),
                          ),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Retour'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}
