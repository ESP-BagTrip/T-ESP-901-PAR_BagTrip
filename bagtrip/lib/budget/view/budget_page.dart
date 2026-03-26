import 'package:bagtrip/budget/bloc/budget_bloc.dart';
import 'package:bagtrip/budget/view/budget_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BudgetPage extends StatelessWidget {
  final String tripId;
  final String role;
  final bool isCompleted;

  const BudgetPage({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BudgetBloc()..add(LoadBudget(tripId: tripId)),
      child: BudgetView(tripId: tripId, role: role, isCompleted: isCompleted),
    );
  }
}
