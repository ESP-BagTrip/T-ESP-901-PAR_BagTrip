import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class HomeTopCards extends StatelessWidget {
  const HomeTopCards({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      {'title': 'VOL', 'icon': Icons.flight_takeoff},
      {'title': 'HÔTEL', 'icon': Icons.hotel},
      {'title': 'AUTRES', 'icon': Icons.explore},
    ];

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: ColorName.secondary),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              card['icon'] as IconData,
                              color: ColorName.primaryLight,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              card['title'] as String,
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                color: ColorName.primaryLight,
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
        ),
        const SizedBox(height: 12),
        // Dots indicator (simplified without PageController)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    index == 0
                        ? ColorName.secondary
                        : ColorName.primarySoftLight,
              ),
            );
          }),
        ),
      ],
    );
  }
}
