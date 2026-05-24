import 'package:bagtrip/components/adaptive/adaptive_indicator.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AdaptiveIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.space16),
            Text(
              message!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.hint),
            ),
          ],
        ],
      ),
    );
  }
}
