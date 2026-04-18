import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Editorial one-liner placed just below the hero. A thin accent line sits
/// on the left as a visual bookmark, the text is serif and slightly muted
/// so the hero image stays the loudest element on screen.
class ReviewSummaryLine extends StatelessWidget {
  const ReviewSummaryLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        AppSpacing.space32,
        AppSpacing.space24,
        AppSpacing.space16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 52,
            margin: const EdgeInsets.only(top: 4, right: AppSpacing.space16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ColorName.primary, ColorName.primaryDark],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 22,
                height: 1.35,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.3,
                color: AppColors.reviewInk.withValues(alpha: 0.88),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
