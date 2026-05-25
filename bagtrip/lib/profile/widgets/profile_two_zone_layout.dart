import 'package:bagtrip/components/bottom_tab_bar.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

/// Profile screen layout: [ColorName.primaryDark] header zone + rounded sheet.
class ProfileTwoZoneLayout extends StatelessWidget {
  const ProfileTwoZoneLayout({
    super.key,
    required this.header,
    required this.children,
  });

  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top + AppSpacing.space16;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final tabBarInset = AdaptivePlatform.isIOS
        ? BottomTabBar.visualHeight(context)
        : 0.0;
    final bottomInset = safeBottom + tabBarInset + AppSpacing.space24;
    final sheetColor = AppColors.profileSheetBackgroundOf(
      Theme.of(context).brightness,
    );

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
                    AppSpacing.space24,
                  ),
                  child: header,
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
                        children: children,
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
