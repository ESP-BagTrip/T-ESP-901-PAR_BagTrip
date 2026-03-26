import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a platform-appropriate edit dialog with a text field.
///
/// Returns the new value or `null` if the user cancelled.
Future<String?> showAdaptiveEditDialog({
  required BuildContext context,
  required String title,
  String? currentValue,
  required String confirmLabel,
  required String cancelLabel,
  String? placeholder,
  TextInputType? keyboardType,
}) {
  final controller = TextEditingController(text: currentValue);

  if (AdaptivePlatform.isIOS) {
    return showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: keyboardType,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: placeholder,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
