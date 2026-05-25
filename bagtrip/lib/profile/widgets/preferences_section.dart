import 'package:bagtrip/components/adaptive/adaptive_action_sheet.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/widgets/settings/settings_style.dart';
import 'package:bagtrip/profile/widgets/profile_menu_group_card.dart';
import 'package:bagtrip/profile/widgets/settings/settings_icon_badge.dart';
import 'package:bagtrip/profile/widgets/settings/settings_labeled_content.dart';
import 'package:bagtrip/profile/widgets/settings/settings_theme_segmented_control.dart';
import 'package:bagtrip/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreferencesSection extends StatelessWidget {
  const PreferencesSection({super.key});

  static const _rowPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space16,
    vertical: AppSpacing.space12,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormSectionHeader(
              label: l10n.preferencesTitle,
              icon: Icons.language_outlined,
            ),
            ProfileMenuGroupCard(
              children: [
                _buildLanguageRow(context, settingsState.selectedLanguage),
                _buildThemeBlock(context, settingsState.selectedTheme),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageRow(BuildContext context, String selectedLanguage) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showAdaptiveActionSheet(
            context: context,
            title: l10n.languageLabel,
            actions: [
              AdaptiveAction(
                label: l10n.languageFrench,
                onPressed: () => context.read<SettingsBloc>().add(
                  ChangeLanguage('Français'),
                ),
              ),
              AdaptiveAction(
                label: l10n.languageEnglish,
                onPressed: () =>
                    context.read<SettingsBloc>().add(ChangeLanguage('English')),
              ),
            ],
          );
        },
        child: Padding(
          padding: _rowPadding,
          child: Row(
            children: [
              SettingsIconBadge(
                icon: Icons.language_outlined,
                iconColor: SettingsStyle.iconAccentSecondary(),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: SettingsLabeledContent(
                  label: l10n.languageLabel,
                  title: _languageDisplay(context, selectedLanguage),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: SettingsStyle.chevronColor(Theme.of(context).brightness),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _languageDisplay(BuildContext context, String value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 'Français':
        return l10n.languageFrench;
      case 'English':
        return l10n.languageEnglish;
      default:
        return value;
    }
  }

  Widget _buildThemeBlock(BuildContext context, String currentTheme) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: _rowPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsIconBadge(
                icon: Icons.dark_mode_outlined,
                iconColor: SettingsStyle.iconAccentMuted(),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: SettingsLabeledContent(
                  label: l10n.themeLabel,
                  title: l10n.chooseThemeHint,
                  boldTitle: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          SettingsThemeSegmentedControl(
            selectedTheme: currentTheme,
            lightLabel: l10n.themeLight,
            darkLabel: l10n.themeDark,
            systemLabel: l10n.themeSystem,
            onThemeChanged: (theme) {
              context.read<SettingsBloc>().add(ChangeTheme(theme));
            },
          ),
        ],
      ),
    );
  }
}
