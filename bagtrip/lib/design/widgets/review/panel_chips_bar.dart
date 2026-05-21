import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class PanelChipsBar extends StatelessWidget {
  const PanelChipsBar({
    super.key,
    required this.labels,
    required this.controller,
    this.incompleteFlags,
  }) : assert(
         incompleteFlags == null || incompleteFlags.length == labels.length,
         'incompleteFlags length must match labels length',
       );

  final List<String> labels;
  final TabController controller;
  final List<bool>? incompleteFlags;

  /// Exposed for tests (corner radius rules).
  @visibleForTesting
  static BoxDecoration indicatorDecorationForIndex(int index, int tabCount) {
    return _indicatorDecoration(index, tabCount);
  }

  static BoxDecoration _indicatorDecoration(int index, int tabCount) {
    final r = const Radius.circular(AppRadius.cornerRaidus8);
    if (tabCount <= 1) {
      return BoxDecoration(
        color: ColorName.surfaceVariant,
        borderRadius: BorderRadius.only(topLeft: r, topRight: r),
      );
    }
    final isFirst = index == 0;
    final isLast = index == tabCount - 1;
    return BoxDecoration(
      color: ColorName.surfaceVariant,
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? Radius.zero : r,
        topRight: isLast ? Radius.zero : r,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabCount = labels.length;

    return ColoredBox(
      color: ColorName.primaryTrueDark,
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return TabBar(
              controller: controller,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
              ),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelColor: ColorName.surface,
              labelColor: ColorName.primaryTrueDark,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: _indicatorDecoration(controller.index, tabCount),
              tabs: List<Widget>.generate(labels.length, (index) {
                final showBadge = incompleteFlags?[index] ?? false;
                return Tab(
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(labels[index]),
                      if (showBadge) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: ColorName.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
