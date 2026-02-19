import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/personalization/widgets/personalization_layout_grid.dart';
import 'package:bagtrip/personalization/widgets/personalization_select_card.dart';
import 'package:flutter/material.dart';

class CompanionsStepContent extends StatelessWidget {
  const CompanionsStepContent({
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
      ('solo', l10n.personalizationCompanionSolo, '🧳'),
      ('couple', l10n.personalizationCompanionCouple, '💑'),
      ('family', l10n.personalizationCompanionFamily, '👨‍👩‍👧‍👦'),
      ('friends', l10n.personalizationCompanionFriends, '👥'),
    ];
    return PersonalizationLayoutGrid(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.space16,
      crossAxisSpacing: AppSpacing.space16,
      children:
          options.map((opt) {
            return PersonalizationSelectCard(
              emoji: opt.$3,
              label: opt.$2,
              selected: selectedId == opt.$1,
              onTap: () => onSelect(opt.$1),
            );
          }).toList(),
    );
  }
}
