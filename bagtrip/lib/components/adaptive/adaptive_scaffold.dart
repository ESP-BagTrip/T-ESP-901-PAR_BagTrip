import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Renders [Scaffold] on Android and [CupertinoPageScaffold] on iOS.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    this.appBar,
    this.cupertinoNavigationBar,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final CupertinoNavigationBar? cupertinoNavigationBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    if (AdaptivePlatform.isIOS) {
      final bg =
          backgroundColor ?? CupertinoTheme.of(context).scaffoldBackgroundColor;
      return CupertinoPageScaffold(
        navigationBar: cupertinoNavigationBar,
        backgroundColor: bg,
        child: SafeArea(
          child: Material(color: bg, child: body),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
