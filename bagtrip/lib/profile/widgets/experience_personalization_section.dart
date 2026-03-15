import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/widgets/profile_section_card.dart';
import 'package:flutter/material.dart';
import 'package:bagtrip/navigation/route_definitions.dart';

/// Profile section that navigates to the experience personalization flow.
class ExperiencePersonalizationSection extends StatelessWidget {
  const ExperiencePersonalizationSection({
    super.key,
    this.travelTypes = const [],
    this.travelStyle,
    this.budget,
    this.companions,
  });

  final List<String> travelTypes;
  final String? travelStyle;
  final String? budget;
  final String? companions;

  bool get _hasPreferences =>
      travelTypes.isNotEmpty ||
      travelStyle != null ||
      budget != null ||
      companions != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileSectionCard(
      onTap: () => const PersonalizationRoute(from: 'profile').push(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: ColorName.secondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  l10n.personalizationProfileSectionTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ColorName.primaryTrueDark,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ColorName.primaryTrueDark.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
          if (!_hasPreferences) ...[
            const SizedBox(height: AppSpacing.space8),
            Text(
              l10n.profileConfigurePreferences,
              style: TextStyle(
                fontSize: 13,
                color: ColorName.primaryTrueDark.withValues(alpha: 0.5),
              ),
            ),
          ],
          if (_hasPreferences) ...[
            const SizedBox(height: AppSpacing.space8),
            if (travelTypes.isNotEmpty)
              Wrap(
                spacing: AppSpacing.space8,
                runSpacing: 4,
                children: travelTypes
                    .map(
                      (type) => Chip(
                        label: Text(type, style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: ColorName.secondary.withValues(
                          alpha: 0.1,
                        ),
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
            if (travelStyle != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.profileStyleLabel(travelStyle!),
                style: TextStyle(
                  fontSize: 13,
                  color: ColorName.primaryTrueDark.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (budget != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.profileBudgetLabel(budget!),
                style: TextStyle(
                  fontSize: 13,
                  color: ColorName.primaryTrueDark.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (companions != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.profileCompanionsLabel(companions!),
                style: TextStyle(
                  fontSize: 13,
                  color: ColorName.primaryTrueDark.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
