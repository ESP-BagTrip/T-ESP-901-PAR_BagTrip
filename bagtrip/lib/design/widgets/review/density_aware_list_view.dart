import 'package:bagtrip/design/subpage_state.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

/// [ListView.separated] variant that adapts its padding and separator
/// spacing to the current [HeroDensity].
///
/// - **sparse** — 24pt outer padding, 16pt between cards. Cards have room
///   to breathe so 1–3 items feel considered.
/// - **dense** — 12pt outer padding, 8pt between cards. Content takes
///   visual priority.
///
/// The bottom padding always leaves room for a sticky footer CTA
/// (96pt: 72 for the button + 24 breathing).
class DensityAwareListView<T> extends StatelessWidget {
  const DensityAwareListView({
    super.key,
    required this.density,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.leading,
    this.trailing,
    this.footerReserved = 96,
  });

  /// Current layout density. Accepts dense/sparse only — blankCanvas is
  /// rendered by [BlankCanvasHero], not a list.
  final HeroDensity density;

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final ScrollController? controller;

  /// Optional widget rendered above the first item (e.g. filter chips row,
  /// alert banner). Not separated by the list separator.
  final Widget? leading;

  /// Optional widget rendered below the last item (e.g. disclaimer).
  final Widget? trailing;

  /// Reserved bottom inset for the scroll-reactive footer CTA.
  final double footerReserved;

  @override
  Widget build(BuildContext context) {
    assert(
      density != HeroDensity.blankCanvas,
      'DensityAwareListView does not render for blankCanvas state — '
      'use BlankCanvasHero instead.',
    );
    final isSparse = density == HeroDensity.sparse;
    final outer = isSparse ? AppSpacing.space24 : AppSpacing.space12;
    final separator = isSparse ? AppSpacing.space16 : AppSpacing.space8;

    final leadingCount = leading != null ? 1 : 0;
    final trailingCount = trailing != null ? 1 : 0;
    final totalCount = items.length + leadingCount + trailingCount;

    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.only(
        left: outer,
        right: outer,
        top: outer,
        bottom: outer + footerReserved,
      ),
      itemCount: totalCount,
      separatorBuilder: (_, _) => SizedBox(height: separator),
      itemBuilder: (context, index) {
        if (leadingCount > 0 && index == 0) return leading!;
        final adjustedIndex = index - leadingCount;
        if (adjustedIndex < items.length) {
          return itemBuilder(context, items[adjustedIndex], adjustedIndex);
        }
        return trailing!;
      },
    );
  }
}
