import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Greeting block for the dark home header zone ([ColorName.primaryDark]).
class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
  });

  final String greeting;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontFamily: FontFamily.dMSerifDisplay,
            fontSize: 34,
            fontWeight: FontWeight.w400,
            color: ColorName.surface,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 16,
            color: ColorName.surface.withValues(alpha: 0.72),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
