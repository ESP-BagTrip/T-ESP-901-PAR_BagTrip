import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/personalization/widgets/personalization_single_select_card.dart';
import 'package:flutter/material.dart';

class BudgetStepContent extends StatelessWidget {
  const BudgetStepContent({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  final String? selectedId;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (
        'economical',
        l10n.personalizationBudgetEconomical,
        l10n.personalizationBudgetEconomicalDesc,
        Icons.account_balance_wallet_outlined,
      ),
      (
        'moderate',
        l10n.personalizationBudgetModerate,
        l10n.personalizationBudgetModerateDesc,
        Icons.star_outline,
      ),
      (
        'luxury',
        l10n.personalizationBudgetLuxury,
        l10n.personalizationBudgetLuxuryDesc,
        Icons.diamond_outlined,
      ),
    ];
    return Column(
      children:
          options.map((opt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space16),
              child: PersonalizationSingleSelectCard(
                icon: opt.$4,
                label: opt.$2,
                description: opt.$3,
                selected: selectedId == opt.$1,
                onTap: () => onSelect(opt.$1),
              ),
            );
          }).toList(),
    );
  }
}
