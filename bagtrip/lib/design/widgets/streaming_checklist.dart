import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// A single item in a [StreamingChecklist].
class StreamingChecklistItem {
  final String label;
  final IconData icon;
  final bool isDone;

  const StreamingChecklistItem({
    required this.label,
    required this.icon,
    required this.isDone,
  });
}

/// Animated checklist that visualises SSE generation progress.
///
/// Each row fades in with a staggered delay and shows a check icon that
/// cross-fades from pending (radio_button_unchecked) to done (check_circle).
/// A success haptic fires when the last item transitions to done.
class StreamingChecklist extends StatefulWidget {
  final List<StreamingChecklistItem> items;

  const StreamingChecklist({super.key, required this.items});

  @override
  State<StreamingChecklist> createState() => _StreamingChecklistState();
}

class _StreamingChecklistState extends State<StreamingChecklist> {
  @override
  void didUpdateWidget(covariant StreamingChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.isEmpty) return;

    final lastOld = oldWidget.items.isNotEmpty
        ? oldWidget.items.last.isDone
        : false;
    final lastNew = widget.items.last.isDone;

    if (!lastOld && lastNew) {
      AppHaptics.success();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.items.length; i++)
          StaggeredFadeIn(
            index: i,
            baseDelay: AppAnimations.staggerDelay,
            child: _buildRow(widget.items[i]),
          ),
      ],
    );
  }

  Widget _buildRow(StreamingChecklistItem item) {
    return Padding(
      padding: AppSpacing.verticalSpace4,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: AppAnimations.microInteraction,
            child: Icon(
              item.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(item.isDone),
              size: 20,
              color: item.isDone ? ColorName.success : ColorName.hint,
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Icon(
            item.icon,
            size: 20,
            color: item.isDone ? ColorName.primary : ColorName.hint,
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                fontWeight: item.isDone ? FontWeight.bold : FontWeight.normal,
                color: item.isDone ? ColorName.primaryTrueDark : ColorName.hint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
