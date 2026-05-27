// SMP-330 — "Change cover" bottom sheet.
//
// Shows the trip's current `coverImageCandidates`, lets the user tap one
// to swap (PATCH /trips/{id}), or hit "Find more" to re-pick a fresh
// batch (POST /trips/{id}/cover/refresh). The widget is BLoC-aware so
// the parent only has to push it via [showCoverImagePickerSheet].

import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_cover_candidate.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showCoverImagePickerSheet(
  BuildContext context, {
  required TripDetailBloc bloc,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider<TripDetailBloc>.value(
      value: bloc,
      child: const _CoverImagePickerSheet(),
    ),
  );
}

class _CoverImagePickerSheet extends StatelessWidget {
  const _CoverImagePickerSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<TripDetailBloc, TripDetailState>(
      buildWhen: (prev, next) =>
          prev is! TripDetailLoaded ||
          next is! TripDetailLoaded ||
          prev.trip.coverImageUrl != next.trip.coverImageUrl ||
          prev.trip.coverImageCandidates.length !=
              next.trip.coverImageCandidates.length,
      builder: (context, state) {
        if (state is! TripDetailLoaded) {
          return const SizedBox.shrink();
        }
        final trip = state.trip;
        final candidates = trip.coverImageCandidates;
        final brightness = Theme.of(context).brightness;
        final sheetColor = AppColors.profileSheetBackgroundOf(brightness);
        return Container(
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.reviewUncheckedOf(brightness),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.coverPickerTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                if (candidates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.coverPickerEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(brightness),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 16 / 10,
                          ),
                      itemCount: candidates.length,
                      itemBuilder: (context, i) {
                        final candidate = candidates[i];
                        final isCurrent = candidate.url == trip.coverImageUrl;
                        return _CoverTile(
                          trip: trip,
                          candidate: candidate,
                          isCurrent: isCurrent,
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<TripDetailBloc>().add(
                          RefreshTripCoverFromDetail(),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.coverPickerFindMore),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoverTile extends StatelessWidget {
  const _CoverTile({
    required this.trip,
    required this.candidate,
    required this.isCurrent,
  });

  final Trip trip;
  final TripCoverCandidate candidate;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: isCurrent
          ? null
          : () {
              context.read<TripDetailBloc>().add(
                SelectTripCoverFromDetail(coverImageUrl: candidate.url),
              );
              Navigator.of(context).pop();
            },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: AppRadius.medium8,
            child: OptimizedImage.tripCover(candidate.url),
          ),
          if (isCurrent)
            Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.medium8,
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              alignment: Alignment.topRight,
              padding: const EdgeInsets.all(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  l10n.coverPickerCurrentBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (candidate.attribution != null)
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  candidate.attribution!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
