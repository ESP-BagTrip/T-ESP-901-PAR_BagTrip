import 'package:bagtrip/design/widgets/split_flap_text.dart';
import 'package:flutter/material.dart';

class SplitFlapDemoPage extends StatelessWidget {
  const SplitFlapDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1118),
      appBar: AppBar(
        title: const Text('Split-Flap Demo'),
        backgroundColor: const Color(0xFF0C1118),
      ),
      body: const Center(
        child: SplitFlapText(
          text: 'PARIS CDG 13:45',
          duration: Duration(milliseconds: 2400),
          textStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF3F7FF),
            letterSpacing: 1.2,
          ),
          backgroundColor: Color(0xFF0F151F),
          flapColor: Color(0xFF1A2330),
        ),
      ),
    );
  }
}
