import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: ElegantEmptyState(
        icon: Icons.explore_off_rounded,
        title: l10n.notFoundTitle,
        subtitle: l10n.notFoundSubtitle,
        ctaLabel: l10n.notFoundCta,
        ctaIcon: Icons.home_rounded,
        onCta: () => context.go('/home'),
      ),
    );
  }
}
