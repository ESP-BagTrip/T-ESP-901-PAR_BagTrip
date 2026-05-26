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
  });

  final String greeting;
  final String subtitle;
  final List<Widget> topChildren;
  final List<Widget> bottomChildren;

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

    return ColoredBox(
      color: ColorName.primaryDark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minSheetHeight = (constraints.maxHeight * 0.42).clamp(
            280.0,
            double.infinity,
          );

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    topInset,
                    AppSpacing.space16,
                    AppSpacing.space16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeGreetingHeader(
                        greeting: greeting,
                        subtitle: subtitle,
                      ),
                      if (topChildren.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.space16),
                        ...topChildren,
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minSheetHeight),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: sheetColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.cornerRadius32),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.space16,
                        AppSpacing.space24,
                        AppSpacing.space16,
                        bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: bottomChildren,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
