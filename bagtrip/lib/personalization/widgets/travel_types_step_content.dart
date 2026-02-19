import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/personalization/widgets/personalization_layout_grid.dart';
import 'package:bagtrip/personalization/widgets/personalization_select_card.dart';
import 'package:flutter/material.dart';

const List<String> _travelTypeIds = [
  'beach',
  'adventure',
  'city',
  'gastronomy',
  'wellness',
  'nightlife',
];

class TravelTypesStepContent extends StatelessWidget {
  const TravelTypesStepContent({
    super.key,
    required this.selectedIds,
    required this.onToggle,
  });

  final Set<String> selectedIds;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      'beach': l10n.personalizationTravelTypeBeach,
      'adventure': l10n.personalizationTravelTypeAdventure,
      'city': l10n.personalizationTravelTypeCity,
      'gastronomy': l10n.personalizationTravelTypeGastronomy,
      'wellness': l10n.personalizationTravelTypeWellness,
      'nightlife': l10n.personalizationTravelTypeNightlife,
    };
    const emojis = {
      'beach': '🏖️',
      'adventure': '⛰️',
      'city': '🏙️',
      'gastronomy': '🍽️',
      'wellness': '🧘',
      'nightlife': '🎉',
    };

    return PersonalizationLayoutGrid(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.space16,
      crossAxisSpacing: AppSpacing.space16,
      children:
          _travelTypeIds.map((id) {
            final selected = selectedIds.contains(id);
            return PersonalizationSelectCard(
              emoji: emojis[id]!,
              label: labels[id]!,
              selected: selected,
              onTap: () => onToggle(id),
            );
          }).toList(),
    );
  }
}
