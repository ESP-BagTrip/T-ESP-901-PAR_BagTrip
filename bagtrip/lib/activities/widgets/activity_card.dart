import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/status_badge.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onValidate;
  final bool isViewer;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onEdit,
    required this.onDelete,
    this.onValidate,
    this.isViewer = false,
  });

  List<AdaptiveContextAction> _buildContextActions(AppLocalizations l10n) {
    final actions = <AdaptiveContextAction>[
      AdaptiveContextAction(
        label: l10n.contextMenuEdit,
        icon: CupertinoIcons.pencil,
        onPressed: onEdit,
      ),
      if (activity.validationStatus == ValidationStatus.suggested &&
          onValidate != null)
        AdaptiveContextAction(
          label: l10n.contextMenuValidate,
          icon: CupertinoIcons.checkmark_circle,
          onPressed: onValidate!,
        ),
      AdaptiveContextAction(
        label: l10n.contextMenuDelete,
        icon: CupertinoIcons.delete,
        onPressed: onDelete,
        isDestructive: true,
      ),
    ];
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final useContextMenu = AdaptivePlatform.isIOS && !isViewer;
    final semanticTime = [
      activity.startTime,
      activity.endTime,
    ].whereType<String>().join(' - ');
    final semanticStatus =
        activity.validationStatus == ValidationStatus.suggested
        ? l10n.activityToValidate
        : activity.validationStatus == ValidationStatus.validated
        ? l10n.activityValidated
        : '';

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large16,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(child: Icon(activity.category.icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(activity.title)),
                    if (activity.validationStatus ==
                        ValidationStatus.suggested) ...[
                      const SizedBox(width: 8),
                      const StatusBadge(type: StatusType.pending),
                    ],
                    if (activity.validationStatus ==
                        ValidationStatus.validated) ...[
                      const SizedBox(width: 8),
                      const StatusBadge(type: StatusType.confirmed),
                    ],
                  ],
                ),
                if (activity.startTime != null || activity.endTime != null)
                  Text(
                    [
                      activity.startTime,
                      activity.endTime,
                    ].whereType<String>().join(' - '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (activity.location != null)
                  Text(
                    activity.location!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (activity.estimatedCost != null && !isViewer)
                  Text(
                    '${activity.estimatedCost!.toStringAsFixed(2)} \u20ac',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (!isViewer && !useContextMenu)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
                if (value == 'validate') onValidate?.call();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.editButton)),
                if (activity.validationStatus == ValidationStatus.suggested)
                  PopupMenuItem(
                    value: 'validate',
                    child: Text(l10n.activityValidateConfirm),
                  ),
                PopupMenuItem(value: 'delete', child: Text(l10n.deleteButton)),
              ],
            ),
        ],
      ),
    );

    final semanticCard = Semantics(
      label: l10n.activityCardSemanticLabel(
        activity.title,
        semanticTime,
        activity.location ?? '',
        semanticStatus,
      ),
      excludeSemantics: true,
      child: cardContent,
    );

    if (useContextMenu) {
      return AdaptiveContextMenu(
        actions: _buildContextActions(l10n),
        child: semanticCard,
      );
    }

    return semanticCard;
  }
}
