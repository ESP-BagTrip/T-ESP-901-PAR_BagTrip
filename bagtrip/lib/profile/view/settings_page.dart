import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/widgets/notification_preferences_section.dart';
import 'package:bagtrip/profile/widgets/preferences_section.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final sheetBackground = AppColors.profileSheetBackgroundOf(brightness);
    final foreground = AppColors.profileMenuTitleOf(brightness);

    return Scaffold(
      backgroundColor: sheetBackground,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: sheetBackground,
        foregroundColor: foreground,
        iconTheme: IconThemeData(color: foreground),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.space16,
          AppSpacing.space24,
          AppSpacing.space16,
          AppSpacing.space24,
        ),
        child: Column(
          children: [
            PreferencesSection(),
            SizedBox(height: AppSpacing.space24),
            NotificationPreferencesSection(),
          ],
        ),
      ),
    );
  }
}
