import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/personalization/widgets/personalization_single_select_card.dart';
import 'package:flutter/material.dart';

class TravelStyleStepContent extends StatelessWidget {
  const TravelStyleStepContent({
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
        'planned',
        l10n.personalizationTravelStylePlanned,
        Icons.assignment_outlined,
      ),
      (
        'flexible',
        l10n.personalizationTravelStyleFlexible,
        Icons.waves_outlined,
      ),
      (
        'spontaneous',
        l10n.personalizationTravelStyleSpontaneous,
        Icons.casino_outlined,
      ),
    ];
    return Column(
      children: options.map((opt) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space16),
          child: PersonalizationSingleSelectCard(
            icon: opt.$3,
            label: opt.$2,
            selected: selectedId == opt.$1,
            onTap: () => onSelect(opt.$1),
          ),
        );
      }).toList(),
    );
  }
}
