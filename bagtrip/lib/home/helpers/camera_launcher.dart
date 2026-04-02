import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchCamera(BuildContext context) async {
  bool launched = false;

  if (AdaptivePlatform.isIOS) {
    final uri = Uri.parse('camera://');
    if (await canLaunchUrl(uri)) {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } else {
    // Android — use intent to open camera
    final uri = Uri.parse(
      'intent://capture#Intent;action=android.media.action.IMAGE_CAPTURE;end',
    );
    if (await canLaunchUrl(uri)) {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  if (!launched && context.mounted) {
    final l10n = AppLocalizations.of(context)!;
    AppSnackBar.showError(context, message: l10n.photoLaunchFailed);
  }
}
