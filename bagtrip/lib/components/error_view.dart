import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.retryIcon = Icons.refresh,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData retryIcon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.allEdgeInsetSpace24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.space16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: Icon(retryIcon),
                label: Text(
                  retryLabel ?? AppLocalizations.of(context)!.retryButton,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
