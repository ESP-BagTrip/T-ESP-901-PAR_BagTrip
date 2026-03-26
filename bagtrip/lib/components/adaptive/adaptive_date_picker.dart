import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a platform-appropriate date picker.
///
/// Android: [showDatePicker] (Material calendar dialog).
/// iOS: [CupertinoDatePicker] in a modal popup (native scrollable wheel).
Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) async {
  if (AdaptivePlatform.isIOS) {
    DateTime? selected;
    final l10n = AppLocalizations.of(context)!;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(l10n.cancelButton),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      selected ??= initialDate;
                      Navigator.of(ctx).pop();
                    },
                    child: Text(l10n.doneButton),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (date) => selected = date,
              ),
            ),
          ],
        ),
      ),
    );
    return selected;
  }

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
  );
}
