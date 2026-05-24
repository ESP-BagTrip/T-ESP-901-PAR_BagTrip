import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// End trip now vs decide later (no API change).
void showEndActiveTripSheet(BuildContext parentContext) {
  final l10n = AppLocalizations.of(parentContext)!;
  showModalBottomSheet<void>(
    context: parentContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _EndActiveTripSheetBody(
      onPostpone: () => Navigator.of(sheetContext).pop(),
      onTerminate: () {
        Navigator.of(sheetContext).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!parentContext.mounted) return;
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                l10n.toastTripCompleted,
                style: const TextStyle(fontFamily: FontFamily.dMSans),
              ),
            ),
          );
          parentContext.read<HomeBloc>().add(CompleteActiveTrip());
        });
      },
    ),
  );
}

class _EndActiveTripSheetBody extends StatelessWidget {
  final VoidCallback onPostpone;
  final VoidCallback onTerminate;

  const _EndActiveTripSheetBody({
    required this.onPostpone,
    required this.onTerminate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space24,
            AppSpacing.space12,
            AppSpacing.space24,
            AppSpacing.space24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              Text(
                l10n.endTripSheetTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                l10n.endTripSheetMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 14,
                  height: 1.35,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              FilledButton(
                onPressed: onTerminate,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA65E76),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.large16,
                  ),
                ),
                child: Text(
                  l10n.endTripSheetTerminate,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
              OutlinedButton(
                onPressed: onPostpone,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.large16,
                  ),
                ),
                child: Text(
                  l10n.endTripSheetPostpone,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
