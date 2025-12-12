import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class HomeFieldRow extends StatelessWidget {
  final IconData icon;
  final Widget field;

  const HomeFieldRow({super.key, required this.icon, required this.field});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: AppSpacing.onlyTopSpace8,
          child: Row(
            children: [
              Container(
                width: AppSize.width42,
                height: AppSize.height42,
                decoration: const BoxDecoration(
                  color: ColorName.primarySoftLight,
                  borderRadius: AppRadius.large16,
                ),
                child: Icon(icon, color: ColorName.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: AppSize.height42,
                  child: Container(
                    alignment: Alignment.center,
                    padding: AppSpacing.horizontalSpace16,
                    decoration: const BoxDecoration(
                      color: ColorName.primarySoftLight,
                      borderRadius: AppRadius.large16,
                    ),
                    child: field,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
