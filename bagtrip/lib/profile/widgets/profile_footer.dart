import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ProfileFooter extends StatelessWidget {
  const ProfileFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.profileFooterText('1.0.0', 2026),
        style: TextStyle(
          fontSize: 12,
          color: ColorName.primaryTrueDark.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
