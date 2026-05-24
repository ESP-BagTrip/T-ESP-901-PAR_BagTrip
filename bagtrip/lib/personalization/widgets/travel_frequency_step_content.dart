import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/personalization/widgets/premium_select_card.dart';
import 'package:flutter/material.dart';

class TravelFrequencyStepContent extends StatelessWidget {
  const TravelFrequencyStepContent({
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
      ('1-2', l10n.personalizationFrequency1_2),
      ('3-5', l10n.personalizationFrequency3_5),
      ('6+', l10n.personalizationFrequency6Plus),
    ];
    return Column(
      children: options.map((opt) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space24),
          child: PremiumSelectCard(
            label: opt.$2,
            selected: selectedId == opt.$1,
            onTap: () => onSelect(opt.$1),
          ),
        );
      }).toList(),
    );
  }
}
