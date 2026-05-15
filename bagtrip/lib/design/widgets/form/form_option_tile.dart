import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Tappable option row for branch-picker sheets (e.g. add accommodation).
class FormOptionTile extends StatelessWidget {
  const FormOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium12,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: BoxDecoration(
            color: ColorName.surfaceLight,
            borderRadius: AppRadius.medium12,
            border: Border.all(color: ColorName.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColorName.secondary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.medium12,
                ),
                child: Icon(icon, color: ColorName.secondary, size: 22),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ColorName.primaryTrueDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        color: ColorName.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ColorName.hint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
