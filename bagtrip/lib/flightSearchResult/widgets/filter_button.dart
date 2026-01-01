import 'package:flutter/material.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';

class FilterButton extends StatelessWidget {
  const FilterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: AppSpacing.allEdgeInsetSpace16,
      decoration: const BoxDecoration(
        color: ColorName.primaryLight,
        borderRadius: AppRadius.large16,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: ColorName.secondary,
              borderRadius: AppRadius.large16,
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.space16),
          const Text(
            'Ajouter vos filtres',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorName.primary,
            ),
          ),
        ],
      ),
    );
  }
}
