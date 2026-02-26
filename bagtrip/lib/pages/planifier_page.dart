import 'package:bagtrip/planifier/bloc/planifier_bloc.dart';
import 'package:bagtrip/planifier/view/planifier_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlanifierPage extends StatelessWidget {
  const PlanifierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlanifierBloc()..add(LoadPlanifier()),
      child: const PlanifierView(),
    );
  }
}
