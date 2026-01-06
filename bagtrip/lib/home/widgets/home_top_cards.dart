import 'package:bagtrip/gen/colors.gen.dart';
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
    final cards = [
      {'title': 'VOL', 'icon': Icons.flight_takeoff},
      {'title': 'HÔTEL', 'icon': Icons.hotel},
      {'title': 'AUTRES', 'icon': Icons.explore},
    ];

    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: controller,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final card = cards[index % cards.length];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          card['icon'] as IconData,
                          color: ColorName.secondary,
                          size: 40,
                        ),
                        // const SizedBox(height: 8),
                        Text(
                          card['title'] as String,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: ColorName.primary,
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
