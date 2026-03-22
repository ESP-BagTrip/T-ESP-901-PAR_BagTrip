import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trips/widgets/trip_card.dart';
import 'package:flutter/material.dart';

class CompletedTripsCarousel extends StatefulWidget {
  final List<Trip> completedTrips;

  const CompletedTripsCarousel({super.key, required this.completedTrips});

  @override
  State<CompletedTripsCarousel> createState() => _CompletedTripsCarouselState();
}

class _CompletedTripsCarouselState extends State<CompletedTripsCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.completedTrips.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
          child: Text(
            l10n.tripManagerCompletedSection.toUpperCase(),
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space12),

        // PageView carousel
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.completedTrips.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final trip = widget.completedTrips[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                ),
                child: GestureDetector(
                  onTap: () => TripHomeRoute(tripId: trip.id).go(context),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0, //
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                    child: TripCard.large(
                      trip: trip,
                      onTap: () => TripHomeRoute(tripId: trip.id).go(context),
                      onShare: () => SharesRoute(
                        tripId: trip.id,
                        role: trip.role ?? 'OWNER',
                      ).push(context),
                      role: trip.role,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.space12),

        // Page indicator dots
        if (widget.completedTrips.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.completedTrips.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 8 : 6,
                height: isActive ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? ColorName.primary : ColorName.shimmerBase,
                ),
              );
            }),
          ),
      ],
    );
  }
}
