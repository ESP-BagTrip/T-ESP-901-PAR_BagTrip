import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/flight_search/view/flight_search_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlanifierManualPage extends StatelessWidget {
  const PlanifierManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlightSearchBloc(),
      child: Scaffold(
        backgroundColor: PersonalizationColors.gradientStart,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: PersonalizationColors.gradientStart,
          foregroundColor: PersonalizationColors.textPrimary,
        ),
        body: const SafeArea(
          left: false,
          right: false,
          child: FlightSearchForm(),
        ),
      ),
    );
  }
}
