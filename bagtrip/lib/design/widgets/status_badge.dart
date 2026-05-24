import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum StatusType { pending, confirmed, forecasted, active, completed }

class StatusBadge extends StatelessWidget {
  final StatusType type;

  const StatusBadge({super.key, required this.type});

  Color _color() {
    return switch (type) {
      StatusType.pending => AppColors.warning,
      StatusType.confirmed => AppColors.success,
      StatusType.forecasted => AppColors.info,
      StatusType.active => AppColors.success,
      StatusType.completed => AppColors.hint,
    };
  }

  String _label(AppLocalizations l10n) {
    return switch (type) {
      StatusType.pending => l10n.statusPending,
      StatusType.confirmed => l10n.statusConfirmed,
      StatusType.forecasted => "l10n.statusForecasted",
      StatusType.active => l10n.statusActive,
      StatusType.completed => l10n.statusCompleted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _color();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        _label(l10n),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
