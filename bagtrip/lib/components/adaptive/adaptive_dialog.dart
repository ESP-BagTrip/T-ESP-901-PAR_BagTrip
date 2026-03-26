import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a platform-appropriate alert dialog.
///
/// On Android: Material [AlertDialog].
/// On iOS: [CupertinoAlertDialog] with [CupertinoDialogAction]s.
Future<T?> showAdaptiveAlertDialog<T>({
  required BuildContext context,
  required String title,
  String? content,
  required String confirmLabel,
  required String cancelLabel,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool isDestructive = false,
}) {
  if (AdaptivePlatform.isIOS) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: content != null ? Text(content) : null,
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              onCancel?.call();
            },
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm?.call();
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  return showDialog<T>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: content != null ? Text(content) : null,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onCancel?.call();
          },
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm?.call();
          },
          style: isDestructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
