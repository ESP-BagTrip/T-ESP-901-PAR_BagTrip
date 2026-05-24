import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Unified modal scaffold for every edit sheet (flight / hotel / activity /
/// baggage / budget / share / dates / travelers). Reproduces the dark
/// hero + white body rhythm of [ReviewHero] in a bottom-sheet shape.
///
/// Expected usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => ReviewBottomSheetScaffold(
///     title: 'Add flight',
///     subtitle: 'TOKYO',
///     primaryLabel: 'Save',
///     onPrimary: () {...},
///     child: MyForm(),
///   ),
/// );
/// ```
class ReviewBottomSheetScaffold extends StatelessWidget {
  const ReviewBottomSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.primaryLabel,
    this.subtitle,
    this.onPrimary,
    this.isSubmitting = false,
    this.secondaryLabel,
    this.onSecondary,
    this.isSecondaryDestructive = false,
    this.onClose,
  });

  /// DM Serif Display title (e.g. "Add flight").
  final String title;

  /// Optional caps subtitle (usually the destination city, e.g. "TOKYO").
  final String? subtitle;

  /// Form content.
  final Widget child;

  /// Primary CTA label.
  final String primaryLabel;

  /// Primary CTA callback. Pass null to disable.
  final VoidCallback? onPrimary;

  /// When true, the primary CTA shows a spinner instead of the label.
  final bool isSubmitting;

  /// Optional secondary action (e.g. "Delete").
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isSecondaryDestructive;

  /// Override the default close behavior (Navigator.pop).
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.cornerRadius24),
      ),
      child: Container(
        color: ColorName.surfaceVariant,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.space12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            // Dark mini hero
            Container(
              color: ColorName.primaryDark,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                AppSpacing.space16,
                AppSpacing.space16,
                AppSpacing.space16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.space4,
                            ),
                            child: Text(
                              subtitle!.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: FontFamily.dMSans,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: ColorName.hint,
                              ),
                            ),
                          ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: ColorName.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HeroNavButton(
                    icon: Icons.close_rounded,
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // White body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space22),
                child: child,
              ),
            ),
            // Footer
            Container(
              color: ColorName.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    AppSpacing.space16,
                    AppSpacing.space16,
                    AppSpacing.space16 + bottomInset,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PillCtaButton(
                        label: primaryLabel,
                        isLoading: isSubmitting,
                        onTap: onPrimary,
                      ),
                      if (secondaryLabel != null) ...[
                        const SizedBox(height: AppSpacing.space8),
                        TextButton(
                          onPressed: onSecondary,
                          style: TextButton.styleFrom(
                            foregroundColor: isSecondaryDestructive
                                ? ColorName.error
                                : ColorName.primaryDark,
                          ),
                          child: Text(
                            secondaryLabel!,
                            style: const TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
