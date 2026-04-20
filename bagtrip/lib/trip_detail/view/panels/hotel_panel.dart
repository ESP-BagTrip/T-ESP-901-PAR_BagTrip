import 'package:bagtrip/accommodations/widgets/manual_accommodation_form.dart';
import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/core/extensions/datetime_ext.dart';
import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/hotel_stats_grid.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/design/widgets/review/sheets/quick_preview_sheet.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Accommodations tab — same contract as the other panels: tap opens a
/// `QuickPreviewSheet`, `+` opens the manual form inline, long-press +
/// swipe for edit / delete. Amadeus search remains on the full page.
class HotelPanel extends StatelessWidget {
  const HotelPanel({
    super.key,
    required this.tripId,
    required this.trip,
    required this.accommodations,
    required this.canEdit,
    required this.isCompleted,
    required this.role,
  });

  final String tripId;
  final Trip trip;
  final List<Accommodation> accommodations;
  final bool canEdit;
  final bool isCompleted;
  final String role;

  void _openFullPage(BuildContext context) {
    AccommodationsRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
      tripStartDate: trip.startDate?.toIso8601String(),
      tripEndDate: trip.endDate?.toIso8601String(),
      destinationIata: trip.destinationIata,
    ).push(context);
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final bloc = context.read<TripDetailBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualAccommodationForm(
        tripId: tripId,
        tripStartDate: trip.startDate,
        tripEndDate: trip.endDate,
        onSave: (data) {
          AppHaptics.medium();
          bloc.add(CreateAccommodationFromDetail(data: data));
        },
      ),
    );
  }

  Future<void> _showEditSheet(BuildContext context, Accommodation acc) async {
    final bloc = context.read<TripDetailBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualAccommodationForm(
        tripId: tripId,
        existing: acc,
        tripStartDate: trip.startDate,
        tripEndDate: trip.endDate,
        onSave: (data) {
          AppHaptics.medium();
          bloc.add(
            UpdateAccommodationFromDetail(accommodationId: acc.id, data: data),
          );
        },
      ),
    );
  }

  void _delete(BuildContext context, Accommodation acc) {
    AppHaptics.medium();
    context.read<TripDetailBloc>().add(
      DeleteAccommodationFromDetail(accommodationId: acc.id),
    );
  }

  Future<void> _showPreview(BuildContext context, Accommodation acc) async {
    final l10n = AppLocalizations.of(context)!;
    AppHaptics.light();
    await showQuickPreviewSheet(
      context: context,
      icon: Icons.hotel_rounded,
      title: acc.name,
      subtitle: acc.address,
      body: _HotelPreviewBody(accommodation: acc, l10n: l10n),
      primaryAction: canEdit
          ? QuickPreviewAction(
              label: l10n.panelActionEdit,
              icon: Icons.edit_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _showEditSheet(context, acc);
              },
            )
          : QuickPreviewAction(
              label: l10n.panelOpenFullAccommodations,
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _openFullPage(context);
              },
            ),
      destructiveAction: canEdit
          ? QuickPreviewAction(
              label: l10n.panelActionDelete,
              icon: Icons.delete_outline_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _delete(context, acc);
              },
              isDestructive: true,
            )
          : null,
      openFullLabel: l10n.panelOpenFullAccommodations,
      onOpenFull: () => _openFullPage(context),
    );
  }

  List<Accommodation> _sorted(List<Accommodation> list) {
    final sorted = [...list]
      ..sort((a, b) {
        final aDate = a.checkIn ?? DateTime(3000);
        final bDate = b.checkIn ?? DateTime(3000);
        return aDate.compareTo(bDate);
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (accommodations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ElegantEmptyState(
          icon: Icons.hotel_rounded,
          title: l10n.emptyAccommodationsTitle,
          subtitle: canEdit ? l10n.emptyAccommodationsSubtitle : null,
          ctaLabel: canEdit ? l10n.panelQuickAddStay : null,
          onCta: canEdit ? () => _showAddSheet(context) : null,
        ),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    final sortedList = _sorted(accommodations);

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space56 + AppSpacing.space40,
          ),
          itemCount: sortedList.length + 1,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.space16),
          itemBuilder: (context, index) {
            if (index == sortedList.length) {
              return Center(
                child: TextButton(
                  onPressed: () => _openFullPage(context),
                  child: Text(
                    l10n.panelOpenFullAccommodations,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ColorName.hint,
                    ),
                  ),
                ),
              );
            }
            final acc = sortedList[index];
            final card = _HotelCard(
              accommodation: acc,
              l10n: l10n,
              locale: locale,
              onTap: () => _showPreview(context, acc),
            );
            if (!canEdit) return card;
            return Dismissible(
              key: ValueKey('accommodation-${acc.id}'),
              direction: DismissDirection.endToStart,
              background: const _DeleteBackground(),
              confirmDismiss: (_) async {
                AppHaptics.medium();
                return true;
              },
              onDismissed: (_) => _delete(context, acc),
              child: AdaptiveContextMenu(
                actions: [
                  AdaptiveContextAction(
                    label: l10n.panelActionEdit,
                    icon: Icons.edit_outlined,
                    onPressed: () => _showEditSheet(context, acc),
                  ),
                  AdaptiveContextAction(
                    label: l10n.panelActionDelete,
                    icon: Icons.delete_outline_rounded,
                    onPressed: () => _delete(context, acc),
                    isDestructive: true,
                  ),
                ],
                child: card,
              ),
            );
          },
        ),
        if (canEdit)
          Positioned(
            bottom: AppSpacing.space24,
            right: AppSpacing.space24,
            child: PanelFab(
              label: l10n.panelQuickAddStay,
              onTap: () => _showAddSheet(context),
            ),
          ),
      ],
    );
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({
    required this.accommodation,
    required this.l10n,
    required this.locale,
    required this.onTap,
  });

  final Accommodation accommodation;
  final AppLocalizations l10n;
  final String locale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final checkIn = accommodation.checkIn;
    final checkOut = accommodation.checkOut;
    final nights = (checkIn != null && checkOut != null)
        ? checkIn.nightsUntil(checkOut).clamp(1, 365)
        : 1;
    final perNight = accommodation.pricePerNight;

    final fmt = DateFormat('d MMM', locale);

    final card = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.large16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.reviewHeroDark, ColorName.primaryDark],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Icon(Icons.hotel_rounded, color: ColorName.surface),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accommodation.name,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ColorName.primaryDark,
                  ),
                ),
                if (accommodation.address != null &&
                    accommodation.address!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    accommodation.address!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                      color: ColorName.hint,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space16),
                HotelStatsGrid(
                  entries: [
                    (
                      l10n.reviewHotelCheckIn,
                      checkIn != null ? fmt.format(checkIn) : '--',
                    ),
                    (
                      l10n.reviewHotelCheckOut,
                      checkOut != null ? fmt.format(checkOut) : '--',
                    ),
                    (l10n.reviewHotelNights, '$nights'),
                    (
                      l10n.reviewHotelPerNight,
                      perNight != null ? perNight.formatPrice() : '--',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.large16,
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _HotelPreviewBody extends StatelessWidget {
  const _HotelPreviewBody({required this.accommodation, required this.l10n});

  final Accommodation accommodation;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final fmt = DateFormat('EEE d MMM', locale);
    final checkIn = accommodation.checkIn;
    final checkOut = accommodation.checkOut;
    final perNight = accommodation.pricePerNight;
    final nights = (checkIn != null && checkOut != null)
        ? checkIn.nightsUntil(checkOut).clamp(1, 365)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (checkIn != null)
          _KVRow(label: l10n.reviewHotelCheckIn, value: fmt.format(checkIn)),
        if (checkOut != null) ...[
          const SizedBox(height: AppSpacing.space8),
          _KVRow(label: l10n.reviewHotelCheckOut, value: fmt.format(checkOut)),
        ],
        if (nights != null) ...[
          const SizedBox(height: AppSpacing.space8),
          _KVRow(label: l10n.reviewHotelNights, value: '$nights'),
        ],
        if (perNight != null) ...[
          const SizedBox(height: AppSpacing.space8),
          _KVRow(
            label: l10n.reviewHotelPerNight,
            value: perNight.formatPrice(),
          ),
        ],
        if (accommodation.notes != null && accommodation.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space16),
          Text(
            accommodation.notes!,
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 13,
              height: 1.5,
              color: ColorName.primaryDark,
            ),
          ),
        ],
      ],
    );
  }
}

class _KVRow extends StatelessWidget {
  const _KVRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: ColorName.hint,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 15,
              color: ColorName.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      decoration: const BoxDecoration(
        color: ColorName.error,
        borderRadius: AppRadius.large16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
