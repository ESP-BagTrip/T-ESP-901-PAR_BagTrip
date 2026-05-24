import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/personalization/widgets/premium_interest_chip.dart';
import 'package:flutter/material.dart';

/// Interest IDs: map to backend travelTypes. Includes photography & shopping.
const List<String> _interestIds = [
  'adventure',
  'beach',
  'city',
  'gastronomy',
  'photography',
  'wellness',
  'shopping',
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
      'adventure': l10n.personalizationTravelTypeAdventure,
      'beach': l10n.personalizationTravelTypeBeach,
      'city': l10n.personalizationTravelTypeCity,
      'gastronomy': l10n.personalizationTravelTypeGastronomy,
      'wellness': l10n.personalizationTravelTypeWellness,
      'photography': l10n.personalizationInterestPhotography,
      'shopping': l10n.personalizationInterestShopping,
    };
    return Wrap(
      spacing: AppSpacing.space16,
      runSpacing: AppSpacing.space16,
      children: _interestIds.map((id) {
        return PremiumInterestChip(
          label: labels[id] ?? id,
          selected: selectedIds.contains(id),
          onTap: () => onToggle(id),
        );
      }).toList(),
    );
  }
}
