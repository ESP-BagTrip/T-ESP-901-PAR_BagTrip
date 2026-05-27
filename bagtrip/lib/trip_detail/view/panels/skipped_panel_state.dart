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
    final brightness = Theme.of(context).brightness;
    final cardColor = AppColors.reviewCardSurfaceOf(brightness);
    final cardBorder = AppColors.reviewCardBorderOf(brightness);
    final inkColor = AppColors.reviewInkOf(brightness);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.space40),
          DecoratedBox(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: AppRadius.large24,
              border: Border.all(color: cardBorder),
              boxShadow: AppColors.reviewCardShadowOf(brightness),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.2,
                      color: AppColors.textSecondaryOf(brightness),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 20,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      color: inkColor,
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
                          style: TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            color: inkColor,
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
