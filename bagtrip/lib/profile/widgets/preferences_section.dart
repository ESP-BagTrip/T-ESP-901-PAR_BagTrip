import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/widgets/profile_section_card.dart';
import 'package:bagtrip/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreferencesSection extends StatelessWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return ProfileSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.language_outlined,
                    color: ColorName.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    AppLocalizations.of(context)!.preferencesTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),
              _buildLanguageRow(context, settingsState.selectedLanguage),
              const SizedBox(height: AppSpacing.space16),
              _buildThemeSelector(context, settingsState.selectedTheme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageRow(BuildContext context, String selectedLanguage) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(
          Icons.language_outlined,
          color: ColorName.secondary.withValues(alpha: 0.7),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.languageLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                selectedLanguage,
                style: TextStyle(fontSize: 14, color: onSurface),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: onSurface.withValues(alpha: 0.4),
          size: 20,
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context, String currentTheme) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.dark_mode_outlined,
              color: ColorName.secondary.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.themeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: onSurface.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    AppLocalizations.of(context)!.chooseThemeHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildThemeOption(
                context,
                'light',
                AppLocalizations.of(context)!.themeLight,
                Icons.light_mode_outlined,
                currentTheme == 'light',
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: _buildThemeOption(
                context,
                'dark',
                AppLocalizations.of(context)!.themeDark,
                Icons.dark_mode_outlined,
                currentTheme == 'dark',
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: _buildThemeOption(
                context,
                'system',
                AppLocalizations.of(context)!.themeSystem,
                Icons.desktop_windows_outlined,
                currentTheme == 'system',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String themeValue,
    String label,
    IconData icon,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        context.read<SettingsBloc>().add(ChangeTheme(themeValue));
      },
      borderRadius: AppRadius.medium8,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: AppSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorName.secondary.withValues(alpha: 0.1)
              : isDark
              ? ColorName.primaryDark
              : ColorName.primaryLight,
          borderRadius: AppRadius.medium8,
          border: Border.all(
            color: isSelected
                ? ColorName.secondary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? ColorName.secondary
                      : onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? ColorName.secondary
                        : onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: ColorName.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: AppColors.surface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
