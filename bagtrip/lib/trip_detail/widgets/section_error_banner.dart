import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// SMP-327 (SMP327-041) — bloc-aware "retry" banner for a trip-detail
/// section that failed to load (deferred fetch).
///
/// Mount it unconditionally at the top of a panel: it reads its own
/// section error straight from [TripDetailBloc] via `context.select` and
/// renders [SizedBox.shrink] when there's no error for [section]. When an
/// error is present it surfaces a soft warning surface with the
/// user-friendly message and a Retry action that dispatches
/// [RetryDeferredSection] — the bloc clears the error on success.
///
/// [section] must match the keys produced by the bloc:
/// `'flights'`, `'accommodations'`, `'baggage'`, `'budget'`, `'shares'`.
class SectionErrorBanner extends StatelessWidget {
  const SectionErrorBanner({super.key, required this.section});

  final String section;

  @override
  Widget build(BuildContext context) {
    final error = context.select<TripDetailBloc, AppError?>((bloc) {
      final state = bloc.state;
      return state is TripDetailLoaded ? state.sectionErrors[section] : null;
    });
    if (error == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.space12),
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.warningBgOf(brightness),
        borderRadius: AppRadius.large16,
        border: Border.all(color: AppColors.warningBorderOf(brightness)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warningIconOf(brightness),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Text(
              toUserFriendlyMessage(error, l10n),
              style: TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.warningTextOf(brightness),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          TextButton(
            onPressed: () => context.read<TripDetailBloc>().add(
              RetryDeferredSection(section: section),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warningTextOf(brightness),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space12,
              ),
            ),
            child: Text(
              l10n.retryButton,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
