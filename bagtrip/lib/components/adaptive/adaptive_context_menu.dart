import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// An action for use in [AdaptiveContextMenu].
class AdaptiveContextAction {
  const AdaptiveContextAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;
}

/// Wraps [child] in a [CupertinoContextMenu] on iOS.
/// On Android (or when [enabled] is false / [actions] is empty), returns
/// [child] unchanged.
class AdaptiveContextMenu extends StatelessWidget {
  final Widget child;
  final List<AdaptiveContextAction> actions;
  final bool enabled;
  final Widget Function(BuildContext, Animation<double>, Widget)?
  previewBuilder;

  const AdaptiveContextMenu({
    super.key,
    required this.child,
    required this.actions,
    this.enabled = true,
    this.previewBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (!AdaptivePlatform.isIOS || !enabled || actions.isEmpty) {
      return child;
    }

    return CupertinoContextMenu.builder(
      actions: actions.map((a) {
        return CupertinoContextMenuAction(
          isDestructiveAction: a.isDestructive,
          trailingIcon: a.icon,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            a.onPressed();
          },
          child: Text(a.label),
        );
      }).toList(),
      builder: (context, animation) {
        if (previewBuilder != null) {
          return previewBuilder!(context, animation, child);
        }

        // Default preview: constrained width, rounded corners, elevated
        return animation.value < CupertinoContextMenu.animationOpensAt
            ? child
            : Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: ClipRRect(
                    borderRadius: AppRadius.large16,
                    child: Material(
                      elevation: 4,
                      borderRadius: AppRadius.large16,
                      child: child,
                    ),
                  ),
                ),
              );
      },
    );
  }
}
