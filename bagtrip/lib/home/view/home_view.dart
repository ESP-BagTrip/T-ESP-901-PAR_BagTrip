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
              Color(0xFFF0F7FA), // #f0f7fa
              Color(0xFFF5F9FB), // #f5f9fb
              Color(0xFFFAFCFD), // #fafcfd
            ],
          ),
        ),
        child: const HomeContent(),
      ),
    );
  }
}
