import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

/// Full-height sheet that hosts a search-and-replace flow for any
/// trip-detail item that can be re-sourced from Amadeus (vols, hôtels).
///
/// The caller composes the inner widget tree (search form, results,
/// confirmation dialog) — this scaffold only owns the chrome:
/// rounded top, back/close buttons, sheet height, scroll context.
///
/// Open it with [showReplaceSearchSheet] to keep the sheet config
/// uniform (95% screen, transparent barrier, dismiss-on-tap-outside
/// suppressed so the user can't lose state mid-search).
class ReplaceSearchSheet extends StatelessWidget {
  const ReplaceSearchSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onClose,
  });

  /// Sheet title (eg. "Remplacer le vol", "Remplacer l'hôtel").
  final String title;

  /// Optional smaller line under the title (eg. "Paris → Tokyo · 2 juin").
  final String? subtitle;

  /// Search form + results body. The caller owns layout + business
  /// logic; the scaffold only wraps it.
  final Widget child;

  /// Override the default close gesture. Defaults to `Navigator.pop`.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final close = onClose ?? () => Navigator.of(context).pop();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.cornerRadius20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.space12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: AppRadius.handleBar,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            _Header(title: title, subtitle: subtitle, onClose: close),
            const Divider(height: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Open a [ReplaceSearchSheet] sized for an inline replace flow:
/// 95% screen height, no tap-outside dismiss (the user must explicitly
/// cancel via the close button so they don't lose mid-search state).
Future<T?> showReplaceSearchSheet<T>({
  required BuildContext context,
  required ReplaceSearchSheet sheet,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.95,
    ),
    builder: (_) => sheet,
  );
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
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
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
          ),
        ],
      ),
    );
  }
}
