import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/profile/widgets/preferences_section.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: PreferencesSection(),
      ),
    );
  }
}
