import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class MapComingSoonView extends StatelessWidget {
  const MapComingSoonView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: ElegantEmptyState(
        icon: Icons.map_outlined,
        title: l10n.mapTitle,
        subtitle: l10n.mapComingSoonSubtitle,
      ),
    );
  }
}
