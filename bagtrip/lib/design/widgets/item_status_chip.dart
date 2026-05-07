import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Validation state of any trip-detail item (Activity, ManualFlight,
/// Accommodation, BudgetItem) — mirrors the backend ``validation_status``
/// enum so the chip can be fed straight from a model field.
enum ItemStatusChipKind { suggested, validated, manual }

/// Single source of truth for the visual state of an item awaiting,
/// confirming, or originating from the user's review. Used by every
/// trip-detail card so a `SUGGESTED` activity, vol, hôtel and dépense
/// share the same visual identity.
class ItemStatusChip extends StatelessWidget {
  const ItemStatusChip({super.key, required this.kind, this.compact = false});

  final ItemStatusChipKind kind;

  /// `true` → icon-only pill (used inside dense card headers).
  /// `false` → icon + localised label (used in sheets / list rows).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = _palette(kind);
    final label = _label(l10n, kind);

    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.space8 : AppSpacing.space12,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppRadius.pill,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(palette.icon, size: 14, color: palette.foreground),
          if (!compact) ...[
            const SizedBox(width: AppSpacing.space4),
            Text(
              label,
              style: TextStyle(
                color: palette.foreground,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(container: true, label: label, child: pill);
  }

  static _ChipPalette _palette(ItemStatusChipKind kind) {
    switch (kind) {
      case ItemStatusChipKind.suggested:
        // Halo doré : la pilule signale qu'un humain doit revoir le row.
        return const _ChipPalette(
          background: Color(0xFFFFF4D6),
          border: Color(0xFFE7C065),
          foreground: Color(0xFF8A6300),
          icon: Icons.auto_awesome,
        );
      case ItemStatusChipKind.validated:
        return _ChipPalette(
          background: AppColors.success.withValues(alpha: 0.12),
          border: AppColors.success.withValues(alpha: 0.45),
          foreground: AppColors.success,
          icon: Icons.check_circle,
        );
      case ItemStatusChipKind.manual:
        return const _ChipPalette(
          background: AppColors.surfaceVariant,
          border: AppColors.border,
          foreground: AppColors.textSecondary,
          icon: Icons.edit_note,
        );
    }
  }

  static String _label(AppLocalizations l10n, ItemStatusChipKind kind) {
    switch (kind) {
      case ItemStatusChipKind.suggested:
        return l10n.itemStatusSuggested;
      case ItemStatusChipKind.validated:
        return l10n.itemStatusValidated;
      case ItemStatusChipKind.manual:
        return l10n.itemStatusManual;
    }
  }

  /// Adapter for the backend enum string (``"SUGGESTED"`` / ``"VALIDATED"``
  /// / ``"MANUAL"``). Anything else falls back to ``manual`` so an unknown
  /// value never crashes the UI.
  static ItemStatusChipKind fromBackend(String? raw) {
    switch (raw) {
      case 'SUGGESTED':
        return ItemStatusChipKind.suggested;
      case 'VALIDATED':
        return ItemStatusChipKind.validated;
      default:
        return ItemStatusChipKind.manual;
    }
  }
}

class _ChipPalette {
  const _ChipPalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
