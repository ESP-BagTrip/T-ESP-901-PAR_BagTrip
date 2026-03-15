import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/planifier_manual/destination/planifier_manual_destination_view.dart';
import 'package:flutter/material.dart';
import 'package:bagtrip/navigation/route_definitions.dart';

class PlanifierManualPage extends StatelessWidget {
  const PlanifierManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: PersonalizationColors.gradientStart,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => const HomeRoute().go(context),
        ),
        title: Text(
          l10n.yourDestinationTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: PersonalizationColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: PersonalizationColors.gradientStart,
        foregroundColor: PersonalizationColors.textPrimary,
      ),
      body: const SafeArea(
        left: false,
        right: false,
        child: PlanifierManualDestinationView(),
      ),
    );
  }
}
