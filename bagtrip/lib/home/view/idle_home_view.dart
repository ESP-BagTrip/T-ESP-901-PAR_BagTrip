import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/destination_carousel.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/widgets/create_trip_card.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/material.dart';

class IdleHomeView extends StatefulWidget {
  final HomeIdle state;

  const IdleHomeView({super.key, required this.state});

  @override
  State<IdleHomeView> createState() => _IdleHomeViewState();
}

class _IdleHomeViewState extends State<IdleHomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutCubic),
    );
    _revealController.forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final name = widget.state.displayName;
    final trips = widget.state.upcomingTrips;
    final totalItems = 1 + trips.length;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final carouselHeight = screenHeight * 0.52;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: PersonalizationColors.backgroundGradientOf(brightness),
        ),
      ),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.07),

                    // Greeting — time-aware, bold, left-aligned
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _timeAwareGreeting(name, l10n),
                            style: TextStyle(
                              fontFamily: FontFamily.dMSerifDisplay,
                              fontSize: 34,
                              fontWeight: FontWeight.w400,
                              color: PersonalizationColors.textPrimaryOf(
                                brightness,
                              ),
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space8),
                          Text(
                            _subtitleText(l10n, trips.length),
                            style: TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 16,
                              color: PersonalizationColors.textTertiaryOf(
                                brightness,
                              ),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.space24),

                    // The carousel
                    SizedBox(
                      height: carouselHeight,
                      child: DestinationCarousel(
                        showIndicators: false,
                        height: carouselHeight,
                        viewportFraction: 0.84,
                        initialPage: trips.isNotEmpty ? 1 : 0,
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return CreateTripCard(
                              isFirstTrip: widget.state.isNewUser,
                            );
                          }
                          final trip = trips[index - 1];
                          return _HomeTripCard(trip: trip);
                        },
                      ),
                    ),

                    const Spacer(),

                    // Bottom padding
                    SizedBox(
                      height: AdaptivePlatform.isIOS ? 100 : AppSpacing.space32,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAwareGreeting(String name, AppLocalizations l10n) {
    if (name.isEmpty) return l10n.homeWelcomeTitle;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.homeGreetingMorning(name);
    if (hour < 18) return l10n.homeGreetingAfternoon(name);
    return l10n.homeGreetingEvening(name);
  }

  String _subtitleText(AppLocalizations l10n, int tripCount) {
    if (tripCount == 0) return l10n.homeSubtitleEmpty;
    if (tripCount == 1) return l10n.homeSubtitleOneTrip;
    return l10n.homeSubtitleTrips(tripCount);
  }
}

/// Premium trip card for the home carousel with press-down animation,
/// cover image, countdown pill, and themed shadows.
class _HomeTripCard extends StatefulWidget {
  final Trip trip;

  const _HomeTripCard({required this.trip});

  @override
  State<_HomeTripCard> createState() => _HomeTripCardState();
}

class _HomeTripCardState extends State<_HomeTripCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String? _countdown(AppLocalizations l10n) {
    final start = widget.trip.startDate;
    if (start == null) return null;
    final now = DateTime.now();
    final days = DateTime(
      start.year,
      start.month,
      start.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days <= 0) return null;
    return l10n.nextTripCountdown(days);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destination = widget.trip.destinationName ?? widget.trip.title ?? '';
    final dateRange = [
      _formatDateShort(widget.trip.startDate),
      _formatDateShort(widget.trip.endDate),
    ].where((s) => s.isNotEmpty).join(' — ');
    final countdown = _countdown(l10n);

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        AppHaptics.light();
        TripHomeRoute(tripId: widget.trip.id).go(context);
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Hero(
          tag: 'trip-${widget.trip.id}',
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space8,
              vertical: AppSpacing.space4,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.large28,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image or gradient placeholder
                  if (widget.trip.coverImageUrl != null &&
                      widget.trip.coverImageUrl!.isNotEmpty)
                    OptimizedImage.tripCover(
                      widget.trip.coverImageUrl!,
                      errorWidget: const _CardGradientPlaceholder(),
                    )
                  else
                    const _CardGradientPlaceholder(),

                  // Gradient scrim
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          ColorName.primaryTrueDark.withValues(alpha: 0.15),
                          ColorName.primaryTrueDark.withValues(alpha: 0.7),
                        ],
                        stops: const [0.3, 0.6, 1.0],
                      ),
                    ),
                  ),

                  // Countdown pill
                  if (countdown != null)
                    Positioned(
                      top: AppSpacing.space16,
                      right: AppSpacing.space16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ColorName.primaryTrueDark.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: AppRadius.pill,
                          border: Border.all(
                            color: PersonalizationColors.surfaceGlassBorder,
                          ),
                        ),
                        child: Text(
                          countdown,
                          style: TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ColorName.surface.withValues(alpha: 0.9),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                  // Destination + dates
                  Positioned(
                    left: AppSpacing.space24,
                    right: AppSpacing.space24,
                    bottom: AppSpacing.space24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          destination.isNotEmpty
                              ? destination
                              : l10n.tripCardNoDestination,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontSize: 26,
                            fontWeight: FontWeight.w400,
                            color: ColorName.surface,
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (dateRange.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.space4),
                          Text(
                            dateRange,
                            style: TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 14,
                              color: ColorName.surface.withValues(alpha: 0.75),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardGradientPlaceholder extends StatelessWidget {
  const _CardGradientPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorName.primary, ColorName.secondary],
        ),
      ),
      child: const Center(
        child: Icon(Icons.flight_rounded, color: ColorName.surface, size: 56),
      ),
    );
  }
}
