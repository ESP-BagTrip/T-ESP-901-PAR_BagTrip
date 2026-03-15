import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// An action for use in [showAdaptiveActionSheet].
class AdaptiveAction {
  const AdaptiveAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  final IconData? icon;
}

/// Shows a platform-appropriate action sheet.
///
/// Android: [showModalBottomSheet] with a list of [ListTile]s.
/// iOS: [CupertinoActionSheet] via [showCupertinoModalPopup].
Future<void> showAdaptiveActionSheet({
  required BuildContext context,
  String? title,
  String? cancelLabel,
  required List<AdaptiveAction> actions,
}) async {
  if (AdaptivePlatform.isIOS) {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: title != null ? Text(title) : null,
        actions: actions
            .map(
              (a) => CupertinoActionSheetAction(
                isDestructiveAction: a.isDestructive,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  a.onPressed();
                },
                child: Text(a.label),
              ),
            )
            .toList(),
        cancelButton: cancelLabel != null
            ? CupertinoActionSheetAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(cancelLabel),
              )
            : null,
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ...actions.map(
            (a) => ListTile(
              leading: a.icon != null ? Icon(a.icon) : null,
              title: Text(
                a.label,
                style: a.isDestructive
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                a.onPressed();
              },
            ),
          ),
        ],
      ),
    ),
  );
}
