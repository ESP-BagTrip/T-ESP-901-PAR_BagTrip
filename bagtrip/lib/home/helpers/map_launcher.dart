import 'package:bagtrip/components/adaptive/adaptive_action_sheet.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchMapNavigation(BuildContext context, String location) async {
  final encoded = Uri.encodeComponent(location);

  if (AdaptivePlatform.isIOS) {
    // Check if Google Maps is installed
    final gmapsUri = Uri.parse('comgooglemaps://');
    final canGmaps = await canLaunchUrl(gmapsUri);

    if (canGmaps) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;

      showAdaptiveActionSheet(
        context: context,
        title: l10n.timelineChooseMapApp,
        actions: [
          AdaptiveAction(
            label: l10n.timelineAppleMaps,
            onPressed: () => _launchUrl('maps:?q=$encoded'),
          ),
          AdaptiveAction(
            label: l10n.timelineGoogleMaps,
            onPressed: () => _launchUrl('comgooglemaps://?q=$encoded'),
          ),
        ],
      );
      return;
    }

    // iOS without Google Maps → Apple Maps
    await _launchUrl('maps:?q=$encoded');
    return;
  }

  // Android → geo intent
  final launched = await _launchUrl('geo:0,0?q=$encoded');
  if (!launched) {
    // Fallback to Google Maps web
    await _launchUrl(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
  }
}

Future<bool> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
