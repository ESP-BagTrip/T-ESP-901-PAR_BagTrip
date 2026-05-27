import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/widgets/hotel_search_sheet.dart';
import 'package:bagtrip/accommodations/widgets/manual_accommodation_form.dart';
import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/core/extensions/datetime_ext.dart';
import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/core/trip_enums.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/design/widgets/replace_search_sheet.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/design/widgets/review/sheets/quick_preview_sheet.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/validation_status.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/view/panels/skipped_panel_state.dart';
import 'package:bagtrip/trip_detail/view/panels/trip_panel_empty_state.dart';
import 'package:bagtrip/trip_detail/widgets/section_error_banner.dart';
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

  Future<void> _showAddSheet(BuildContext context) async {
    final bloc = context.read<TripDetailBloc>();
    await showItemFormSheet<void>(
      context: context,
      child: ManualAccommodationForm(
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
    await showItemFormSheet<void>(
      context: context,
      child: ManualAccommodationForm(
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

  void _validate(BuildContext context, Accommodation acc) {
    AppHaptics.success();
    context.read<TripDetailBloc>().add(
      ValidateAccommodationFromDetail(accommodationId: acc.id),
    );
  }

  /// Phase 5 — collects the booking reference, persists it on the row,
  /// then dispatches the validate event. Hôtel doesn't have a BagTrip
  /// booking branch (Amadeus search-only), so this is the single
  /// validate path the user takes after choosing externally.
  Future<void> _showExternalBookingRefSheet(
    BuildContext parentContext,
    Accommodation acc,
  ) async {
    final l10n = AppLocalizations.of(parentContext)!;
    final bloc = parentContext.read<TripDetailBloc>();
    final controller = TextEditingController(text: acc.bookingReference ?? '');
    final formKey = GlobalKey<FormState>();
    Navigator.of(parentContext).pop();

    Future<void> submit(BuildContext sheetContext) async {
      if (!formKey.currentState!.validate()) return;
      final ref = controller.text.trim();
      Navigator.of(sheetContext).pop();
      bloc.add(
        UpdateAccommodationFromDetail(
          accommodationId: acc.id,
          data: <String, dynamic>{'bookingReference': ref},
        ),
      );
      bloc.add(ValidateAccommodationFromDetail(accommodationId: acc.id));
    }

    await showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.profileSheetBackgroundOf(
              Theme.of(sheetContext).brightness,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.cornerRadius20),
            ),
          ),
          padding: AppSpacing.allEdgeInsetSpace24,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.reviewUncheckedOf(
                        Theme.of(sheetContext).brightness,
                      ),
                      borderRadius: AppRadius.handleBar,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                Text(
                  l10n.activityValidateAction,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  l10n.accommodationReferenceLabel,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 13,
                    color: ColorName.hint,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: l10n.accommodationReferenceLabel,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.space16),
                FilledButton(
                  onPressed: () => submit(sheetContext),
                  child: Text(l10n.activityValidateAction),
                ),
                const SizedBox(height: AppSpacing.space16),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
  }

  /// Phase 5 follow-up — opens the real Amadeus hotel search inside a
  /// ReplaceSearchSheet, prefilled with the trip's destination IATA.
  /// Tapping a result opens a ManualAccommodationForm pre-filled from
  /// the chosen hotel; saving fires ReplaceAccommodationFromDetail
  /// (atomic DELETE+CREATE) instead of plain CreateAccommodation.
  Future<void> _showReplaceSheet(
    BuildContext parentContext,
    Accommodation acc,
  ) async {
    final l10n = AppLocalizations.of(parentContext)!;
    final tripBloc = parentContext.read<TripDetailBloc>();
    Navigator.of(parentContext).pop();

    String addressOf(Map<String, dynamic> hotel) {
      final addr = hotel['address'];
      if (addr is! Map) return '';
      final parts = <String>[];
      if (addr['cityName'] != null) parts.add(addr['cityName'] as String);
      if (addr['countryCode'] != null) {
        parts.add(addr['countryCode'] as String);
      }
      return parts.join(', ');
    }

    void onHotelPicked(BuildContext sheetContext, Map<String, dynamic> hotel) {
      // Close the replace sheet first so the next sheet stacks cleanly
      // on the trip-detail context (no double drag handle).
      Navigator.of(parentContext).pop();
      final name = hotel['name'] as String? ?? '';
      final address = addressOf(hotel);

      showModalBottomSheet<void>(
        context: parentContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ManualAccommodationForm(
          tripId: tripId,
          isEstimatedPrice: true,
          tripStartDate: trip.startDate,
          tripEndDate: trip.endDate,
          prefill: {'name': name, if (address.isNotEmpty) 'address': address},
          onSave: (data) {
            AppHaptics.medium();
            tripBloc.add(
              ReplaceAccommodationFromDetail(
                oldAccommodationId: acc.id,
                newAccommodationData: data,
              ),
            );
          },
        ),
      );
    }

    await showReplaceSearchSheet<void>(
      context: parentContext,
      sheet: ReplaceSearchSheet(
        title: l10n.accommodationEditTitle,
        subtitle: acc.name,
        child: BlocProvider(
          create: (_) => AccommodationBloc(),
          child: Builder(
            builder: (sheetContext) => HotelSearchSheet(
              tripId: tripId,
              initialCityCode: trip.destinationIata,
              tripStartDate: trip.startDate,
              tripEndDate: trip.endDate,
              onHotelSelected: (hotel) => onHotelPicked(sheetContext, hotel),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPreview(BuildContext context, Accommodation acc) async {
    final l10n = AppLocalizations.of(context)!;
    AppHaptics.light();
    final isSuggested = acc.validationStatus == ValidationStatus.suggested;
    await showQuickPreviewSheet(
      context: context,
      icon: Icons.hotel_rounded,
      title: acc.name,
      subtitle: acc.address,
      body: _HotelPreviewBody(accommodation: acc, l10n: l10n),
      // Phase 5 — three-action preview sheet:
      //   Validate -> opens the booking-reference form sheet (single
      //               external branch, hôtels have no BagTrip booking
      //               flow today).
      //   Replace  -> opens ReplaceSearchSheet placeholder. Bloc handler
      //               already supports the atomic DELETE+CREATE.
      //   Delete   -> unchanged.
      // Edit stays accessible via the long-press context menu.
      validateAction: isSuggested && canEdit
          ? QuickPreviewAction(
              label: l10n.activityValidateAction,
              icon: Icons.check_rounded,
              onPressed: () => _showExternalBookingRefSheet(context, acc),
            )
          : null,
      primaryAction: canEdit
          ? QuickPreviewAction(
              label: l10n.flightValidateAmadeusTitle,
              icon: Icons.swap_horiz_rounded,
              onPressed: () => _showReplaceSheet(context, acc),
            )
          : null,
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

  void _toggleTracking(BuildContext context, {required bool skip}) {
    AppHaptics.medium();
    context.read<TripDetailBloc>().add(
      UpdateTripTrackingFromDetail(
        accommodationsTracking: skip
            ? TrackingStatus.skipped
            : TrackingStatus.tracked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionErrorBanner(section: 'accommodations'),
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (trip.accommodationsTracking == TrackingStatus.skipped) {
      return SkippedPanelState(
        title: l10n.panelSkippedAccommodationsTitle,
        message: l10n.panelSkippedAccommodationsMessage,
        resumeLabel: l10n.panelResumeAccommodationsCta,
        onResume: canEdit ? () => _toggleTracking(context, skip: false) : null,
      );
    }
    if (accommodations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TripPanelEmptyState(
              icon: Icons.hotel_rounded,
              title: l10n.emptyAccommodationsTitle,
              ctaLabel: l10n.emptyAccommodationsAddNow,
              tripStartDate: trip.startDate,
              canEdit: canEdit,
              onCta: canEdit ? () => _showAddSheet(context) : null,
            ),
            if (canEdit) ...[
              const SizedBox(height: AppSpacing.space16),
              TextButton(
                onPressed: () => _toggleTracking(context, skip: true),
                child: Text(
                  l10n.panelSkipAccommodationsCta,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    color: ColorName.hint,
                  ),
                ),
              ),
            ],
          ],
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
          itemCount: sortedList.length + (canEdit ? 1 : 0),
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.space16),
          itemBuilder: (context, index) {
            if (canEdit && index == sortedList.length) {
              return Center(
                child: TextButton(
                  onPressed: () => _toggleTracking(context, skip: true),
                  child: Text(
                    l10n.panelSkipAccommodationsCta,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      color: ColorName.hint,
                    ),
                  ),
                ),
              );
            }
            final acc = sortedList[index];
            final hotelCard = _HotelCard(
              accommodation: acc,
              l10n: l10n,
              locale: locale,
              onTap: () => _showPreview(context, acc),
            );
            final card = hotelCard;
            if (!canEdit) return card;
            final isSuggested =
                acc.validationStatus == ValidationStatus.suggested;
            return Dismissible(
              key: ValueKey('accommodation-${acc.id}'),
              direction: isSuggested
                  ? DismissDirection.horizontal
                  : DismissDirection.endToStart,
              background: const _SwipeActionBackground(
                color: ColorName.secondary,
                icon: Icons.check_rounded,
                alignment: Alignment.centerLeft,
              ),
              secondaryBackground: const _SwipeActionBackground(
                color: ColorName.error,
                icon: Icons.delete_outline_rounded,
                alignment: Alignment.centerRight,
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  _validate(context, acc);
                  return false;
                }
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
    final brightness = Theme.of(context).brightness;
    final localeCode = Localizations.localeOf(context).languageCode;
    final surfaceColor = AppColors.surfaceGroupOf(brightness);
    final titleColor = AppColors.profileMenuTitleOf(brightness);
    final mutedColor = AppColors.profileMenuMutedOf(brightness);
    final checkIn = accommodation.checkIn;
    final checkOut = accommodation.checkOut;
    final nights = (checkIn != null && checkOut != null)
        ? checkIn.nightsUntil(checkOut).clamp(1, 365)
        : 1;
    final perNight = accommodation.pricePerNight;
    final totalStay = perNight != null ? perNight * nights : null;
    final location = _shortAddress(accommodation.address);
    final totalStayLabel = localeCode == 'fr' ? 'TOTAL SÉJOUR' : 'TOTAL STAY';
    final accommodationLabel = localeCode == 'fr'
        ? 'HÉBERGEMENT'
        : 'ACCOMMODATION';

    final fmt = DateFormat('d MMM', locale);

    final card = Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.large16,
        border: Border.all(
          color: AppColors.reviewCardBorderOf(brightness),
          width: 0.5,
        ),
        boxShadow: AppColors.reviewCardShadowOf(brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: ColorName.primaryTrueDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              AppSpacing.space12,
              AppSpacing.space16,
              AppSpacing.space16,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ColorName.secondary.withValues(alpha: 0.14),
                    borderRadius: AppRadius.large16,
                    border: Border.all(
                      color: ColorName.secondary.withValues(alpha: 0.4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.menu_book_outlined,
                    size: 20,
                    color: ColorName.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accommodationLabel,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: ColorName.surface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        '$location \u00b7 ${l10n.reviewHotelStayNights(nights)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ColorName.surface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space12,
                    vertical: AppSpacing.space8,
                  ),
                  decoration: BoxDecoration(
                    color: ColorName.secondary.withValues(alpha: 0.14),
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: ColorName.secondary),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: ColorName.secondary,
                      ),
                      SizedBox(width: AppSpacing.space4),
                      Text(
                        'IA',
                        style: TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ColorName.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accommodation.name,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                if (accommodation.address != null &&
                    accommodation.address!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    accommodation.address!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                      color: mutedColor,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space16),
                Row(
                  children: [
                    Expanded(
                      child: _MetaCard(
                        label: l10n.reviewHotelCheckIn,
                        value: checkIn != null ? fmt.format(checkIn) : '--',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: _MetaCard(
                        label: l10n.reviewHotelCheckOut,
                        value: checkOut != null ? fmt.format(checkOut) : '--',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  decoration: BoxDecoration(
                    color: AppColors.reviewAccentSurfaceOf(brightness),
                    borderRadius: AppRadius.large16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        totalStayLabel,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,

                          color: ColorName.secondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        totalStay != null ? totalStay.formatPrice() : '--',
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSerifDisplay,
                          fontSize: 18,
                          height: 1,
                          fontWeight: FontWeight.w600,
                          color: ColorName.surface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        perNight != null
                            ? '${perNight.formatPrice()} / ${l10n.reviewHotelPerNight.toLowerCase()}'
                            : '--',
                        style: TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ColorName.surface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
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

  String _shortAddress(String? rawAddress) {
    if (rawAddress == null || rawAddress.trim().isEmpty) return '--';
    final chunk = rawAddress.split(',').first.trim();
    return chunk.isEmpty ? '--' : chunk;
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGroupOf(brightness),
        borderRadius: AppRadius.large16,
        border: Border.all(color: AppColors.reviewCardBorderOf(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 12,
              fontWeight: FontWeight.w700,

              color: AppColors.textSecondaryOf(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            value,
            style: TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w600,
              color: AppColors.profileMenuTitleOf(brightness),
            ),
          ),
        ],
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

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space16),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.large16),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
