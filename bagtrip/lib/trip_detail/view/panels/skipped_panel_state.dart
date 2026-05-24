import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Rendered when the user opts out of BagTrip tracking for a domain
/// (flights or accommodations). Mirrors the luxury review look: ivory paper,
/// serif title, muted copy, single text-button affordance to resume tracking.
class SkippedPanelState extends StatelessWidget {
  const SkippedPanelState({
    super.key,
    required this.title,
    required this.message,
    required this.resumeLabel,
    this.onResume,
  });

  final String title;
  final String message;
  final String resumeLabel;
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.space40),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFBFAF7),
              borderRadius: AppRadius.large24,
              border: Border.all(
                color: const Color(0xFF0D1F35).withValues(alpha: 0.06),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.2,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 20,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      color: AppColors.reviewInk,
                    ),
                  ),
                  if (onResume != null) ...[
                    const SizedBox(height: AppSpacing.space24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onResume,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          resumeLabel,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            color: AppColors.reviewInk,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
