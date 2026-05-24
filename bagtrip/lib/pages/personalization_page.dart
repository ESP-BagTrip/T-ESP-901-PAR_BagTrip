import 'package:bagtrip/personalization/bloc/personalization_bloc.dart';
import 'package:bagtrip/personalization/view/personalization_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Entry point for the 4-step personalization flow.
/// Provides [PersonalizationBloc] and delegates to [PersonalizationView].
class PersonalizationPage extends StatelessWidget {
  const PersonalizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PersonalizationBloc()..add(LoadPersonalization()),
      child: const PersonalizationView(),
    );
  }
}
