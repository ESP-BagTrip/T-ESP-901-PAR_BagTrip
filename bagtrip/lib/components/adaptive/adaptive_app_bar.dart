import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Returns an [AppBar] on Android and a [CupertinoNavigationBar] on iOS.
///
/// Usage: pass the result of [AdaptiveAppBar.build] as the [appBar] /
/// [cupertinoNavigationBar] parameter of [AdaptiveScaffold], or use
/// it directly in a [Scaffold].
class AdaptiveAppBar {
  const AdaptiveAppBar._();

  /// Builds a platform-appropriate app bar.
  ///
  /// On iOS the navigation bar is translucent with a blur effect,
  /// mimicking the native iOS look.
  static PreferredSizeWidget build({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    PreferredSizeWidget? bottom,
  }) {
    if (AdaptivePlatform.isIOS) {
      return _CupertinoAppBarAdapter(
        title: title,
        actions: actions,
        leading: leading,
      );
    }

    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      bottom: bottom,
    );
  }
}

/// Wraps [CupertinoNavigationBar] in a [PreferredSizeWidget] so it can be
/// used as [Scaffold.appBar].
class _CupertinoAppBarAdapter extends StatelessWidget
    implements PreferredSizeWidget {
  const _CupertinoAppBarAdapter({
    required this.title,
    this.actions,
    this.leading,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(
      middle: Text(title),
      leading: leading,
      trailing: actions != null && actions!.isNotEmpty
          ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
          : null,
      backgroundColor: CupertinoTheme.of(
        context,
      ).barBackgroundColor.withValues(alpha: 0.85),
      border: null,
    );
  }
}
