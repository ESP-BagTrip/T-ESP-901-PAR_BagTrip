import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/models/suggested_baggage_item.dart';
import 'package:flutter/material.dart';

class BaggageSuggestionCard extends StatefulWidget {
  final SuggestedBaggageItem suggestion;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const BaggageSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  State<BaggageSuggestionCard> createState() => _BaggageSuggestionCardState();
}

class _BaggageSuggestionCardState extends State<BaggageSuggestionCard>
    with SingleTickerProviderStateMixin {
  double _opacity = 1.0;

  void _fadeAndCallback(VoidCallback callback) {
    setState(() => _opacity = 0.0);
    Future.delayed(const Duration(milliseconds: 300), callback);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.large16,
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoftLight,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            widget.suggestion.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
          subtitle: widget.suggestion.reason != null
              ? Text(
                  widget.suggestion.reason!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.hint),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: AppColors.success,
                iconSize: 24,
                onPressed: () => _fadeAndCallback(widget.onAccept),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: AppColors.hint,
                iconSize: 20,
                onPressed: () => _fadeAndCallback(widget.onDismiss),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
