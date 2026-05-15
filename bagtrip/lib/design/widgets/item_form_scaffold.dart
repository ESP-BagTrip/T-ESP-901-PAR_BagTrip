import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/item_status_chip.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Standard bottom-sheet chrome for every trip-detail item form
/// (activity, vol, hôtel, dépense). Keyboard padding, drag handle,
/// rounded top, scroll behaviour are all handled here so each form
/// only ships the three things that are actually different — its
/// title, its fields, and its primary action(s).
///
/// Call sites should never reach for `showModalBottomSheet` directly
/// for an edit/create item form: use [showItemFormSheet] so the sheet
/// stays visually consistent across the app.
class ItemFormSheetLayout {
  const ItemFormSheetLayout._();

  /// Max height as a fraction of the screen (classic bottom sheet, not fullscreen).
  static const double maxHeightFactor = 0.8;
}

class ItemFormScaffold extends StatelessWidget {
  const ItemFormScaffold({
    super.key,
    required this.title,
    required this.fields,
    required this.actions,
    this.statusKind,
    this.subtitle,
    this.onClose,
  });

  /// Sheet title (eg. "Modifier le vol", "Nouvelle dépense").
  final String title;

  /// Optional smaller line under the title (eg. flight route, day).
  final String? subtitle;

  /// When the underlying item carries a `validation_status`, plug it
  /// in to render the chip next to the title — keeps "I am editing a
  /// SUGGESTED item" honest at glance.
  final ItemStatusChipKind? statusKind;

  /// Form body. Wrap your fields in a `Column` (or single widget);
  /// the scaffold provides the scroll view and the keyboard padding.
  final Widget fields;

  /// Bottom action area. Pass primary + secondary in display order;
  /// they are rendered inside a `Row` with even spacing.
  final List<Widget> actions;

  /// Override the default close gesture. Defaults to `Navigator.pop`.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight =
        MediaQuery.sizeOf(context).height * ItemFormSheetLayout.maxHeightFactor;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: ColorName.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.cornerRadius20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.space12),
              _DragHandle(),
              const SizedBox(height: AppSpacing.space12),
              _Header(
                title: title,
                subtitle: subtitle,
                statusKind: statusKind,
                onClose: onClose ?? () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpacing.space4),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    AppSpacing.space16,
                    AppSpacing.space16,
                    AppSpacing.space24,
                  ),
                  child: fields,
                ),
              ),
              if (actions.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    AppSpacing.space8,
                    AppSpacing.space16,
                    AppSpacing.space16 + safeBottom,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.space12),
                        Expanded(child: actions[i]),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a bottom sheet with the standard item-form chrome (transparent
/// barrier, scroll-controlled). Pass [ItemFormScaffold] directly, or a
/// wrapper such as [ManualFlightForm] that embeds one.
Future<T?> showItemFormSheet<T>({
  required BuildContext context,
  required Widget child,
  double maxHeightFactor = ItemFormSheetLayout.maxHeightFactor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final maxHeight =
          MediaQuery.sizeOf(sheetContext).height * maxHeightFactor;
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: child,
        ),
      );
    },
  );
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.3),
          borderRadius: AppRadius.handleBar,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.statusKind,
    required this.onClose,
  });

  final String title;
  final String? subtitle;
  final ItemStatusChipKind? statusKind;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        0,
        AppSpacing.space8,
        AppSpacing.space12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ColorName.primaryTrueDark,
                        ),
                      ),
                    ),
                    if (statusKind != null) ...[
                      const SizedBox(width: AppSpacing.space8),
                      ItemStatusChip(kind: statusKind!),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onClose,
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: ColorName.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: ColorName.textMutedLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
