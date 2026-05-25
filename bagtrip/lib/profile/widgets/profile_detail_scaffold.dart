import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

/// Shared shell for profile sub-pages (settings, personal info, subscription).
class ProfileDetailScaffold extends StatelessWidget {
  const ProfileDetailScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final sheetBackground = AppColors.profileSheetBackgroundOf(brightness);
    final foreground = AppColors.profileMenuTitleOf(brightness);

    return Scaffold(
      backgroundColor: sheetBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: sheetBackground,
        foregroundColor: foreground,
        iconTheme: IconThemeData(color: foreground),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: body,
    );
  }
}

/// Standard scroll padding for profile detail pages.
class ProfileDetailScrollBody extends StatelessWidget {
  const ProfileDetailScrollBody({
    super.key,
    required this.children,
    this.bottomPadding = AppSpacing.space24,
  });

  final List<Widget> children;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space24,
        AppSpacing.space16,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
