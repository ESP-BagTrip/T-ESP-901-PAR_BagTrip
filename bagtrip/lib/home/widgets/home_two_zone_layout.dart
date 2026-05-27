import 'package:bagtrip/components/bottom_tab_bar.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/home/widgets/home_greeting_header.dart';
import 'package:flutter/material.dart';

/// Home screen layout: [ColorName.primaryDark] top zone + rounded bottom sheet.
class HomeTwoZoneLayout extends StatelessWidget {
  const HomeTwoZoneLayout({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.bottomChildren,
    this.topChildren = const [],
    this.includeTopSafeArea = false,
    this.showBottomSheet = true,
  });

  final String greeting;
  final String subtitle;
  final List<Widget> topChildren;
  final List<Widget> bottomChildren;

  /// When false, content stays in the top zone only (e.g. idle home with no trips).
  final bool showBottomSheet;

  /// When true, adds status-bar inset to the top zone (active trip home).
  /// When false, the parent [SafeArea] already handles it (idle home).
  final bool includeTopSafeArea;

  @override
  Widget build(BuildContext context) {
    final sheetColor = AppColors.profileSheetBackgroundOf(
      Theme.of(context).brightness,
    );
    final topInset = includeTopSafeArea
        ? MediaQuery.paddingOf(context).top + AppSpacing.space16
        : AppSpacing.space24;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final tabBarInset = AdaptivePlatform.isIOS
        ? BottomTabBar.visualHeight(context)
        : 0.0;
    final bottomInset = safeBottom + tabBarInset + AppSpacing.space24;

    final topZoneChildren = <Widget>[
      HomeGreetingHeader(greeting: greeting, subtitle: subtitle),
      if (topChildren.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.space16),
        ...topChildren,
      ],
      if (!showBottomSheet && bottomChildren.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.space24),
        ...bottomChildren,
      ],
    ];

    final topPadding = EdgeInsets.fromLTRB(
      AppSpacing.space16,
      topInset,
      AppSpacing.space16,
      showBottomSheet ? AppSpacing.space16 : bottomInset,
    );

    final sheetPadding = EdgeInsets.fromLTRB(
      AppSpacing.space16,
      AppSpacing.space24,
      AppSpacing.space16,
      bottomInset,
    );

    final sheetDecoration = BoxDecoration(
      color: sheetColor,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.cornerRadius32),
      ),
    );

    final header = Padding(
      padding: topPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: topZoneChildren,
      ),
    );

    return ColoredBox(
      color: ColorName.primaryDark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slivers = <Widget>[SliverToBoxAdapter(child: header)];

          if (showBottomSheet) {
            final sheetMinHeight = (constraints.maxHeight * 0.55).clamp(
              240.0,
              double.infinity,
            );
            slivers.add(
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: sheetMinHeight),
                  child: DecoratedBox(
                    decoration: sheetDecoration,
                    child: Padding(
                      padding: sheetPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: bottomChildren,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: slivers,
          );
        },
      ),
    );
  }
}
