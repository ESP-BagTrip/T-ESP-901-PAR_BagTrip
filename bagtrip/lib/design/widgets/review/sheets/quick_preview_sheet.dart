import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Quick-action describing one button in a [QuickPreviewSheet] actions bar.
class QuickPreviewAction {
  const QuickPreviewAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;
}

/// Light-weight bottom sheet surfaced when the user taps an item on a panel.
///
/// Avoids forcing navigation for a detail peek: shows the item's summary,
/// offers one primary action (usually Edit), optional secondary and
/// destructive actions, and an opt-in "Open full" footer that is the only
/// affordance that navigates to the corresponding sub-page.
class QuickPreviewSheet extends StatelessWidget {
  const QuickPreviewSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryAction,
    this.subtitle,
    this.secondaryAction,
    this.destructiveAction,
    this.openFullLabel,
    this.onOpenFull,
    this.initialChildSize = 0.55,
    this.minChildSize = 0.35,
    this.maxChildSize = 0.92,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget body;
  final QuickPreviewAction primaryAction;
  final QuickPreviewAction? secondaryAction;
  final QuickPreviewAction? destructiveAction;
  final String? openFullLabel;
  final VoidCallback? onOpenFull;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const _Handle(),
                _Header(icon: icon, title: title, subtitle: subtitle),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space24,
                      AppSpacing.space8,
                      AppSpacing.space24,
                      AppSpacing.space16,
                    ),
                    child: body,
                  ),
                ),
                _Actions(
                  primary: primaryAction,
                  secondary: secondaryAction,
                  destructive: destructiveAction,
                  openFullLabel: openFullLabel,
                  onOpenFull: onOpenFull == null
                      ? null
                      : () {
                          AppHaptics.light();
                          Navigator.of(sheetContext).pop();
                          onOpenFull!();
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: ColorName.hint.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        AppSpacing.space22,
        AppSpacing.space24,
        AppSpacing.space16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorName.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: ColorName.primary),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null) ...[
                  Text(
                    subtitle!.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: ColorName.hint,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 22,
                    color: ColorName.primaryDark,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.primary,
    required this.secondary,
    required this.destructive,
    required this.openFullLabel,
    required this.onOpenFull,
  });

  final QuickPreviewAction primary;
  final QuickPreviewAction? secondary;
  final QuickPreviewAction? destructive;
  final String? openFullLabel;
  final VoidCallback? onOpenFull;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: ColorName.primarySoftLight)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space12,
        AppSpacing.space16,
        AppSpacing.space12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillCtaButton(
            label: primary.label,
            leadingIcon: primary.icon,
            onTap: () {
              AppHaptics.medium();
              primary.onPressed();
            },
          ),
          if (secondary != null || destructive != null) ...[
            const SizedBox(height: AppSpacing.space8),
            Row(
              children: [
                if (secondary != null)
                  Expanded(
                    child: _GhostButton(
                      action: secondary!,
                      color: ColorName.primaryDark,
                    ),
                  ),
                if (secondary != null && destructive != null)
                  const SizedBox(width: AppSpacing.space8),
                if (destructive != null)
                  Expanded(
                    child: _GhostButton(
                      action: destructive!,
                      color: ColorName.error,
                    ),
                  ),
              ],
            ),
          ],
          if (openFullLabel != null && onOpenFull != null) ...[
            const SizedBox(height: AppSpacing.space8),
            TextButton(
              onPressed: onOpenFull,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    openFullLabel!,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ColorName.hint,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: ColorName.hint,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.action, required this.color});

  final QuickPreviewAction action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        if (action.isDestructive) {
          AppHaptics.success();
        } else {
          AppHaptics.light();
        }
        action.onPressed();
      },
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space12),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      icon: Icon(action.icon, size: 16),
      label: Text(
        action.label,
        style: const TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Convenience: opens [QuickPreviewSheet] with the standard modal parameters
/// (transparent background, scrollable, top safe-area aware).
Future<void> showQuickPreviewSheet({
  required BuildContext context,
  required IconData icon,
  required String title,
  required Widget body,
  required QuickPreviewAction primaryAction,
  String? subtitle,
  QuickPreviewAction? secondaryAction,
  QuickPreviewAction? destructiveAction,
  String? openFullLabel,
  VoidCallback? onOpenFull,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => QuickPreviewSheet(
      icon: icon,
      title: title,
      subtitle: subtitle,
      body: body,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      destructiveAction: destructiveAction,
      openFullLabel: openFullLabel,
      onOpenFull: onOpenFull,
    ),
  );
}
