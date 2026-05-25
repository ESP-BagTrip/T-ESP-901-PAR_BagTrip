import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

/// White card grouping multiple [ProfileMenuRow] items with dividers.
class ProfileMenuGroupCard extends StatelessWidget {
  const ProfileMenuGroupCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = AppColors.surfaceGroupBorderOf(theme.brightness);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceGroupOf(theme.brightness),
        borderRadius: AppRadius.large20,
        border: Border.all(color: borderColor),
        boxShadow: theme.brightness == Brightness.dark ? null : AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildChildrenWithDividers(context),
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    if (children.isEmpty) return const [];
    final dividerColor = AppColors.surfaceGroupBorderOf(
      Theme.of(context).brightness,
    );
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        result.add(Divider(height: 1, thickness: 1, color: dividerColor));
      }
      result.add(children[i]);
    }
    return result;
  }
}
