import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Returns an [AppBar] on Android and a [GlassAppBar] on iOS.
///
/// On iOS, [GlassAppBar] does **not** auto-inject a back arrow when the
/// route can pop — Material does, Cupertino doesn't. So pages reached
/// via `context.go(...)` end up looking marooned (no way back, no
/// visual link to the parent stack). To match the Material default and
/// avoid every caller having to remember a `leading:` argument, this
/// helper resolves a back button on iOS when the current route can pop
/// and no explicit leading was passed.
class AdaptiveAppBar {
  const AdaptiveAppBar._();

  static PreferredSizeWidget build({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    PreferredSizeWidget? bottom,
  }) {
    if (AdaptivePlatform.isIOS) {
      return _GlassAppBarAdapter(
        title: title,
        actions: actions,
        leading: leading,
        bottom: bottom,
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

/// Wraps [GlassAppBar] in a [PreferredSizeWidget] so it can be
/// used as [Scaffold.appBar].
class _GlassAppBarAdapter extends StatelessWidget
    implements PreferredSizeWidget {
  const _GlassAppBarAdapter({
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(44 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    // Auto-resolve a back button on iOS when the route can pop and no
    // explicit leading was passed. Mirrors Material `AppBar` behaviour.
    final resolvedLeading =
        leading ??
        (ModalRoute.of(context)?.canPop == true
            ? const CupertinoNavigationBarBackButton()
            : null);

    final glassBar = GlassAppBar(
      useOwnLayer: true,
      title: Text(title),
      leading: resolvedLeading,
      actions: actions != null && actions!.isNotEmpty ? actions : null,
    );

    if (bottom == null) return glassBar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [glassBar, bottom!],
    );
  }
}
