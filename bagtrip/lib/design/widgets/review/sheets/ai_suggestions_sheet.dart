import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Generic bottom sheet that renders an AI-suggestion list. The card body is
/// fully owned by the caller via [itemBuilder], so each domain (activities,
/// accommodations, baggage, …) can keep its domain-specific presentation
/// while sharing the chrome: dark mini hero + caps subtitle + scrollable
/// body + optional disclaimer footer.
///
/// Keep the surface dark to match the `ReviewHero` / `ReviewBottomSheetScaffold`
/// vocabulary — the sheet lives in the same visual family as the wizard
/// review step.
class AiSuggestionsSheet<T> extends StatelessWidget {
  const AiSuggestionsSheet({
    super.key,
    required this.title,
    required this.suggestions,
    required this.itemBuilder,
    this.subtitle,
    this.disclaimer,
    this.emptyTitle,
    this.emptySubtitle,
    this.initialChildSize = 0.7,
    this.maxChildSize = 0.95,
    this.minChildSize = 0.3,
  });

  /// Hero title (DM Serif Display, 20px).
  final String title;

  /// Optional caps subtitle shown under the title (e.g. domain hint).
  final String? subtitle;

  /// Optional disclaimer text shown at the bottom of the list. Useful for
  /// AI-attribution copy ("Suggestions powered by AI — verify before booking").
  final String? disclaimer;

  /// Title for the empty state when [suggestions] is empty.
  final String? emptyTitle;

  /// Subtitle for the empty state when [suggestions] is empty.
  final String? emptySubtitle;

  final List<T> suggestions;

  /// Builds one suggestion card. The [sheetContext] lets the caller
  /// `Navigator.of(sheetContext).pop()` before opening a follow-up sheet;
  /// the parent context can still be captured by closing over it at the
  /// `showModalBottomSheet` call site.
  final Widget Function(BuildContext sheetContext, T item, int index)
  itemBuilder;

  final double initialChildSize;
  final double maxChildSize;
  final double minChildSize;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      maxChildSize: maxChildSize,
      minChildSize: minChildSize,
      expand: false,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: ColorName.primaryDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _Handle(),
              _Header(
                title: title,
                subtitle: subtitle,
                onClose: () => Navigator.of(sheetContext).pop(),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: ColorName.surfaceVariant,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: suggestions.isEmpty
                      ? _EmptyState(title: emptyTitle, subtitle: emptySubtitle)
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.space16,
                            AppSpacing.space24,
                            AppSpacing.space16,
                            AppSpacing.space24,
                          ),
                          itemCount:
                              suggestions.length + (disclaimer != null ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.space12),
                          itemBuilder: (itemCtx, index) {
                            if (index == suggestions.length &&
                                disclaimer != null) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.space16,
                                ),
                                child: Text(
                                  disclaimer!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: FontFamily.dMSans,
                                    fontSize: 11,
                                    color: ColorName.hint,
                                    height: 1.4,
                                  ),
                                ),
                              );
                            }
                            return itemBuilder(
                              sheetContext,
                              suggestions[index],
                              index,
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
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
                if (subtitle != null) ...[
                  Text(
                    subtitle!.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          HeroNavButton(icon: Icons.close_rounded, onPressed: onClose),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: ColorName.hint,
            ),
            const SizedBox(height: AppSpacing.space16),
            if (title != null)
              Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSerifDisplay,
                  fontSize: 18,
                  color: ColorName.primaryDark,
                ),
              ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.space8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 13,
                  color: ColorName.hint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
