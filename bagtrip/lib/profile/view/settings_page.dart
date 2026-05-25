import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/widgets/notification_preferences_section.dart';
import 'package:bagtrip/profile/widgets/preferences_section.dart';
import 'package:bagtrip/profile/widgets/profile_detail_scaffold.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileDetailScaffold(
      title: l10n.settingsTitle,
      body: const ProfileDetailScrollBody(
        children: [
          PreferencesSection(),
          SizedBox(height: AppSpacing.space24),
          NotificationPreferencesSection(),
        ],
      ),
    );
  }
}
