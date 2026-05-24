import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';

class SectionErrorIndicator extends StatelessWidget {
  final AppError error;
  final VoidCallback onRetry;

  const SectionErrorIndicator({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space24,
        vertical: AppSpacing.space12,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: ColorName.error, size: 20),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              toUserFriendlyMessage(error, l10n),
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                color: ColorName.error,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              l10n.retryButton,
              style: const TextStyle(fontFamily: FontFamily.b612, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
