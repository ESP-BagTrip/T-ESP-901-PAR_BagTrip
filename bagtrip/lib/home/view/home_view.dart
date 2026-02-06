import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/home/view/home_content.dart';
import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorName.backgroundGradientStart,
              ColorName.backgroundGradientMid,
              ColorName.backgroundGradientEnd,
            ],
          ),
        ),
        child: const HomeContent(),
      ),
    );
  }
}
