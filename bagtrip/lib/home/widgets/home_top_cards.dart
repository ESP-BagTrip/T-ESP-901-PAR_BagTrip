import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class HomeTopCards extends StatelessWidget {
  final PageController controller;
  final Function(int) onPageChanged;

  const HomeTopCards({
    super.key,
    required this.controller,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      {
        'title': l10n.flightCardTitle.toUpperCase(),
        'icon': Icons.flight_takeoff,
        'image': 'assets/images/flight.jpg',
      },
      {
        'title': l10n.hotelCardTitle.toUpperCase(),
        'icon': Icons.hotel,
        'image': 'assets/images/hotel.jpg',
      },
      {
        'title': l10n.flightAndHotelCardTitle.toUpperCase(),
        'icon': Icons.explore,
        'image': 'assets/images/flight_hotel.jpg',
      },
    ];

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: controller,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final card = cards[index % cards.length];
          final hasImage = card.containsKey('image');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      image:
                          hasImage
                              ? DecorationImage(
                                image: AssetImage(card['image'] as String),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.3),
                                  BlendMode.darken,
                                ),
                              )
                              : null,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          card['icon'] as IconData,
                          color: hasImage ? Colors.white : ColorName.secondary,
                          size: 40,
                        ),
                        // const SizedBox(height: 8),
                        Text(
                          card['title'] as String,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: hasImage ? Colors.white : ColorName.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
