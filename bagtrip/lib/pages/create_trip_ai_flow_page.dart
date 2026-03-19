import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/create_trip_ai/bloc/create_trip_ai_bloc.dart';
import 'package:bagtrip/create_trip_ai/view/create_trip_ai_recap_view.dart';
import 'package:bagtrip/create_trip_ai/view/create_trip_ai_summary_view.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/navigation/route_definitions.dart';

/// Single entry for the Create Trip AI flow. Provides the bloc and shows
/// Recap, Streaming, or Summary based on state (no route push between steps).
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
            AppSnackBar.showSuccess(
              context,
              message: AppLocalizations.of(context)!.tripCreated,
            );
            const HomeRoute().go(context);
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
              return const Scaffold(body: LoadingView());
            }
            if (state is CreateTripAiStreaming) {
              return const CreateTripAiSummaryView();
            }
            if (state is CreateTripAiSummaryLoaded ||
                state is CreateTripAiTripCreated) {
              return const CreateTripAiSummaryView();
            }
            if (state is CreateTripAiError) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.errorTitle),
                ),
                body: ErrorView(
                  message: toUserFriendlyMessage(
                    state.error,
                    AppLocalizations.of(context)!,
                  ),
                  onRetry: () => context.read<CreateTripAiBloc>().add(
                    CreateTripAiLoadRecap(),
                  ),
                  retryIcon: Icons.arrow_back,
                  retryLabel: AppLocalizations.of(context)!.backButton,
                ),
              );
            }
            return const Scaffold(body: LoadingView());
          },
        ),
      ),
    );
  }
}
