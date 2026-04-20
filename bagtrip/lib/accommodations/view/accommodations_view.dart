import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/widgets/add_accommodation_sheet.dart';
import 'package:bagtrip/accommodations/widgets/hotel_search_sheet.dart';
import 'package:bagtrip/accommodations/widgets/manual_accommodation_form.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/extensions/datetime_ext.dart';
import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/subpage_state.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/design/widgets/review/animated_count.dart';
import 'package:bagtrip/design/widgets/review/blank_canvas_hero.dart';
import 'package:bagtrip/design/widgets/review/density_aware_list_view.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/design/widgets/review/hotel_stats_grid.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/sheets/ai_suggestions_sheet.dart';
import 'package:bagtrip/design/widgets/review/state_responsive_hero.dart';
import 'package:bagtrip/design/widgets/review/tap_scale_aware.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AccommodationsView extends StatefulWidget {
  final String tripId;
  final String role;
  final bool isCompleted;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;
  final String? destinationIata;

  const AccommodationsView({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
    this.tripStartDate,
    this.tripEndDate,
    this.destinationIata,
  });

  @override
  State<AccommodationsView> createState() => _AccommodationsViewState();
}

class _AccommodationsViewState extends State<AccommodationsView>
    with TickerProviderStateMixin {
  late final PanelFooterCtaController _footerController;

  @override
  void initState() {
    super.initState();
    _footerController = PanelFooterCtaController(vsync: this);
    _footerController.show();
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  bool get _canEdit => widget.role != 'VIEWER' && !widget.isCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        BlocListener<AccommodationBloc, AccommodationState>(
          listenWhen: (_, current) => current is AccommodationQuotaExceeded,
          listener: (context, _) => PremiumPaywall.show(context),
        ),
        BlocListener<AccommodationBloc, AccommodationState>(
          listenWhen: (_, current) => current is AccommodationSuggestionsLoaded,
          listener: (context, state) {
            if (state is AccommodationSuggestionsLoaded) {
              _showSuggestionsSheet(context, state.suggestions);
            }
          },
        ),
        BlocListener<AccommodationBloc, AccommodationState>(
          listenWhen: (_, current) => current is AccommodationsLoaded,
          listener: (context, _) =>
              context.read<TripDetailBloc>().add(RefreshTripDetail()),
        ),
      ],
      child: Scaffold(
        backgroundColor: ColorName.surfaceVariant,
        body: BlocBuilder<AccommodationBloc, AccommodationState>(
          builder: (context, state) {
            final isLoading =
                state is AccommodationLoading ||
                state is AccommodationSuggestionsLoading;
            final hasError = state is AccommodationError;
            final items = state is AccommodationsLoaded
                ? state.accommodations
                : const <Accommodation>[];
            final screenState = resolveSubpageState(
              isLoading: isLoading,
              hasError: hasError,
              count: items.length,
              canEdit: _canEdit,
              isCompleted: widget.isCompleted,
            );
            switch (screenState) {
              case SubpageScreenState.booting:
                return const LoadingView();
              case SubpageScreenState.error:
                return ErrorView(
                  message: toUserFriendlyMessage(
                    (state as AccommodationError).error,
                    l10n,
                  ),
                  onRetry: () => context.read<AccommodationBloc>().add(
                    LoadAccommodations(tripId: widget.tripId),
                  ),
                );
              case SubpageScreenState.blankCanvas:
                return _buildBlankCanvas(context, l10n);
              case SubpageScreenState.sparse:
              case SubpageScreenState.dense:
              case SubpageScreenState.viewer:
              case SubpageScreenState.archive:
                final density = densityOf(screenState)!;
                return _buildPopulated(
                  context,
                  l10n,
                  items,
                  screenState,
                  density,
                );
            }
          },
        ),
      ),
    );
  }

  Widget _buildBlankCanvas(BuildContext context, AppLocalizations l10n) {
    return BlankCanvasHero(
      icon: Icons.hotel_outlined,
      title: l10n.blankAccommodationsTitle,
      subtitle: l10n.blankAccommodationsSubtitle,
      primaryLabel: l10n.blankAccommodationsPrimary,
      primaryLeadingIcon: Icons.add_rounded,
      onPrimary: () {
        AppHaptics.medium();
        _showAddSheet(context);
      },
      secondaryLabel: l10n.blankAccommodationsSecondary,
      secondaryLeadingIcon: Icons.auto_awesome_rounded,
      onSecondary: () {
        AppHaptics.light();
        context.read<AccommodationBloc>().add(
          SuggestAccommodations(tripId: widget.tripId),
        );
      },
      breathingIconBuilder: BlankCanvasBreathing.softShadow(),
    );
  }

  Widget _buildPopulated(
    BuildContext context,
    AppLocalizations l10n,
    List<Accommodation> accommodations,
    SubpageScreenState screenState,
    HeroDensity density,
  ) {
    final isViewer = screenState == SubpageScreenState.viewer;
    final isArchive = screenState == SubpageScreenState.archive;
    final interactive = !isViewer && !isArchive;
    final locale = Localizations.localeOf(context).languageCode;

    final totalNights = accommodations.fold<int>(0, (sum, a) {
      if (a.checkIn == null || a.checkOut == null) return sum;
      return sum + a.checkIn!.nightsUntil(a.checkOut!).clamp(0, 365);
    });

    return Column(
      children: [
        StateResponsiveHero(
          title: l10n.accommodationsTitle,
          density: density,
          meta: AnimatedCount(
            value: accommodations.length,
            formatter: (n) => l10n.accommodationsHeroMeta(n, totalNights),
          ),
          badge: isViewer
              ? HeroBadge(label: l10n.subpageHeroBadgeViewer)
              : isArchive
              ? HeroBadge(
                  label: l10n.subpageHeroBadgeCompleted,
                  tone: HeroBadgeTone.success,
                )
              : null,
          trailing: interactive
              ? [
                  HeroNavButton(
                    icon: Icons.auto_awesome_rounded,
                    tooltip: l10n.accommodationAiSuggestTitle,
                    onPressed: () {
                      AppHaptics.light();
                      context.read<AccommodationBloc>().add(
                        SuggestAccommodations(tripId: widget.tripId),
                      );
                    },
                  ),
                ]
              : null,
        ),
        Expanded(
          child: ScrollReactiveCtaScaffold(
            controller: _footerController,
            body: DensityAwareListView<Accommodation>(
              density: density,
              items: accommodations,
              itemBuilder: (context, acc, _) => _AccommodationRow(
                accommodation: acc,
                locale: locale,
                l10n: l10n,
                canEdit: interactive,
                onEdit: () => _showEditSheet(context, acc),
                onDelete: () {
                  AppHaptics.medium();
                  context.read<AccommodationBloc>().add(
                    DeleteAccommodation(
                      tripId: widget.tripId,
                      accommodationId: acc.id,
                    ),
                  );
                },
              ),
            ),
            footer: interactive
                ? PillCtaButton(
                    label: l10n.accommodationAddTitle,
                    leadingIcon: Icons.add_rounded,
                    onTap: () {
                      AppHaptics.medium();
                      _showAddSheet(context);
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }

  void _showAddSheet(BuildContext context) {
    final bloc = context.read<AccommodationBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AddAccommodationSheet(
          tripId: widget.tripId,
          tripStartDate: widget.tripStartDate,
          tripEndDate: widget.tripEndDate,
          destinationIata: widget.destinationIata,
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, Accommodation acc) {
    final bloc = context.read<AccommodationBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _FormWrapper(
          child: ManualAccommodationForm(
            tripId: widget.tripId,
            existing: acc,
            tripStartDate: widget.tripStartDate,
            tripEndDate: widget.tripEndDate,
          ),
        ),
      ),
    );
  }

  void _showSuggestionsSheet(
    BuildContext context,
    List<Map<String, dynamic>> suggestions,
  ) {
    final bloc = context.read<AccommodationBloc>();
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AiSuggestionsSheet<Map<String, dynamic>>(
          title: l10n.accommodationAiSuggestTitle,
          subtitle: l10n.accommodationsTitle,
          disclaimer: l10n.accommodationAiDisclaimer,
          suggestions: suggestions,
          itemBuilder: (sheetContext, s, _) => _AccommodationSuggestionCard(
            suggestion: s,
            onSearchInArea: () {
              Navigator.of(sheetContext).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: HotelSearchSheet(tripId: widget.tripId),
                ),
              );
            },
            onAddManually: () {
              Navigator.of(sheetContext).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: _FormWrapper(
                    child: ManualAccommodationForm(
                      tripId: widget.tripId,
                      prefill: {
                        'name': s['name'],
                        'neighborhood': s['neighborhood'],
                        'currency': s['currency'],
                      },
                      tripStartDate: widget.tripStartDate,
                      tripEndDate: widget.tripEndDate,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AccommodationRow extends StatelessWidget {
  const _AccommodationRow({
    required this.accommodation,
    required this.locale,
    required this.l10n,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final Accommodation accommodation;
  final String locale;
  final AppLocalizations l10n;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final card = _HotelCard(
      accommodation: accommodation,
      l10n: l10n,
      locale: locale,
    );
    if (!canEdit) return card;
    final tappable = TapScaleAware(
      onTap: () {
        AppHaptics.light();
        onEdit();
      },
      child: card,
    );
    return Dismissible(
      key: ValueKey('accommodation-${accommodation.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space24),
        decoration: const BoxDecoration(
          color: ColorName.error,
          borderRadius: AppRadius.large16,
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: tappable,
    );
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({
    required this.accommodation,
    required this.l10n,
    required this.locale,
  });

  final Accommodation accommodation;
  final AppLocalizations l10n;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final checkIn = accommodation.checkIn;
    final checkOut = accommodation.checkOut;
    final nights = (checkIn != null && checkOut != null)
        ? checkIn.nightsUntil(checkOut).clamp(1, 365)
        : 1;
    final perNight = accommodation.pricePerNight;
    final fmt = DateFormat('d MMM', locale);

    return Container(
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
  }
}

class _AccommodationSuggestionCard extends StatelessWidget {
  const _AccommodationSuggestionCard({
    required this.suggestion,
    required this.onSearchInArea,
    required this.onAddManually,
  });

  final Map<String, dynamic> suggestion;
  final VoidCallback onSearchInArea;
  final VoidCallback onAddManually;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = suggestion;
    final name = s['name'] as String? ?? '';
    final neighborhood = s['neighborhood'] as String? ?? '';
    final priceRange = s['priceRange'] as String? ?? '';
    final currency = s['currency'] as String? ?? 'EUR';
    final reason = s['reason'] as String? ?? '';
    final type = s['type'] as String? ?? 'OTHER';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ColorName.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  _typeLabel(type, l10n),
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: ColorName.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (priceRange.isNotEmpty)
                Text(
                  '$priceRange $currency',
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 14,
                    color: ColorName.primaryDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            name,
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 16,
              color: ColorName.primaryDark,
            ),
          ),
          if (neighborhood.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: ColorName.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  neighborhood,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 12,
                    color: ColorName.secondary,
                  ),
                ),
              ],
            ),
          ],
          if (reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space8),
            Text(
              reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 12,
                color: ColorName.hint,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space12),
          Row(
            children: [
              Expanded(
                child: PillCtaButton(
                  label: l10n.accommodationSearchInArea,
                  variant: PillVariant.outlined,
                  leadingIcon: Icons.search_rounded,
                  onTap: onSearchInArea,
                  height: 40,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: PillCtaButton(
                  label: l10n.accommodationAddManually,
                  leadingIcon: Icons.add_rounded,
                  onTap: onAddManually,
                  height: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type, AppLocalizations l10n) {
    return switch (type) {
      'HOTEL' => l10n.accommodationTypeHotel,
      'AIRBNB' => l10n.accommodationTypeAirbnb,
      'HOSTEL' => l10n.accommodationTypeHostel,
      'GUESTHOUSE' => l10n.accommodationTypeGuesthouse,
      'CAMPING' => l10n.accommodationTypeCamping,
      'RESORT' => l10n.accommodationTypeResort,
      _ => l10n.accommodationTypeOther,
    };
  }
}

class _FormWrapper extends StatelessWidget {
  const _FormWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.cornerRadius24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.space12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorName.hint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
