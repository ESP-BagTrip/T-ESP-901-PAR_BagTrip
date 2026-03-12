import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/personalization/widgets/premium_select_card.dart';
import 'package:flutter/material.dart';

/// Minimal line-style icons (Jonathan Ive / Apple HIG): outline, thin weight.
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
    const iconSize = 22.0;
    final options = [
      ('solo', l10n.personalizationCompanionSolo, Icons.person_outline),
      ('couple', l10n.personalizationCompanionCouple, Icons.favorite_border),
      ('family', l10n.personalizationCompanionFamily, Icons.people_outline),
      ('friends', l10n.personalizationCompanionFriends, Icons.groups_outlined),
    ];
    return Column(
      children:
          options
              .map(
                (opt) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space24),
                  child: PremiumSelectCard(
                    icon: opt.$3,
                    iconSize: iconSize,
                    label: opt.$2,
                    selected: selectedId == opt.$1,
                    onTap: () => onSelect(opt.$1),
                  ),
                ),
              )
              .toList(),
    );
  }
}
