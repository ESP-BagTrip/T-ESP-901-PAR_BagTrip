import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/widgets/profile_section_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Profile section that navigates to the experience personalization flow.
class ExperiencePersonalizationSection extends StatelessWidget {
  const ExperiencePersonalizationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileSectionCard(
      onTap: () => context.push('/personalization'),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: ColorName.secondary, size: 20),
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
    );
  }
}
