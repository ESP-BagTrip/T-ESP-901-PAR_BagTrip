import 'package:flutter/material.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/primary_button.dart';
import 'package:bagtrip/l10n/app_localizations.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppSpacing.allEdgeInsetSpace24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wallet_outlined,
                size: 80,
                color: ColorName.secondary,
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                AppLocalizations.of(context)!.handleBudget,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                AppLocalizations.of(context)!.trackExpensesAndPlan,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorName.primaryTrueDark.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.space32),
              PrimaryButton(
                label: AppLocalizations.of(context)!.addExpense,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
