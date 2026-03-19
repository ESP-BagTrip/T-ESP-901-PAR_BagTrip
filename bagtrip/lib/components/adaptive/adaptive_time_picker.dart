import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a platform-appropriate time picker.
///
/// Android: [showTimePicker] (Material clock dialog).
/// iOS: [CupertinoDatePicker] in time mode via a modal popup.
Future<TimeOfDay?> showAdaptiveTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  if (AdaptivePlatform.isIOS) {
    TimeOfDay? selected;
    final now = DateTime.now();
    final initial = DateTime(
      now.year,
      now.month,
      now.day,
      initialTime.hour,
      initialTime.minute,
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300 + MediaQuery.of(ctx).padding.bottom,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        selected ??= initialTime;
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initial,
                  onDateTimeChanged: (date) {
                    selected = TimeOfDay(hour: date.hour, minute: date.minute);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return selected;
  }

  return showTimePicker(context: context, initialTime: initialTime);
}
