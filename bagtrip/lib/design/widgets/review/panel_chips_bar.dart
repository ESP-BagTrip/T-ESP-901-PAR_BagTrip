import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Horizontal pill-shaped tab bar sitting on `ColorName.primaryDark`.
///
/// Reused by the wizard Review step and by the trip-detail editor to navigate
/// between domain panels (Flights / Hotel / Itinerary / …).
///
/// When [incompleteFlags] is provided (one bool per tab, same length as
/// [labels]), a small dot badge surfaces next to each incomplete tab label.
/// Passing `null` (wizard case) hides badges entirely.
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
      decoration: const BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.pill,
      ),
      child: TabBar(
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 2),
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
        unselectedLabelColor: ColorName.hint,
        labelColor: ColorName.surface,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const BoxDecoration(
          color: ColorName.primaryDark,
          borderRadius: AppRadius.pill,
        ),
        tabs: List<Widget>.generate(labels.length, (index) {
          final showBadge = incompleteFlags?[index] ?? false;
          return Tab(
            height: 36,
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
      ),
    );
  }
}
