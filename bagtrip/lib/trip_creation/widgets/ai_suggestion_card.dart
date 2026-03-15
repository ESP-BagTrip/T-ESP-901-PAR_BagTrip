import 'package:bagtrip/create_trip_ai/models/ai_trip_proposal.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class AiSuggestionCard extends StatelessWidget {
  final AiTripProposal proposal;
  final bool isSelected;
  final VoidCallback onTap;

  const AiSuggestionCard({
    super.key,
    required this.proposal,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ColorName.primary, ColorName.secondary],
                  )
                : null,
            color: isSelected ? null : ColorName.surface,
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : ColorName.primarySoftLight,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? ColorName.primary.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 4),
                blurRadius: isSelected ? 12 : 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: isSelected ? ColorName.surface : ColorName.secondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      proposal.destination,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? ColorName.surface
                            : ColorName.primaryTrueDark,
                      ),
                    ),
                  ),
                ],
              ),
              if (proposal.destinationCountry.isNotEmpty) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    proposal.destinationCountry,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      color: isSelected
                          ? ColorName.surface.withValues(alpha: 0.8)
                          : ColorName.hint,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (proposal.durationDays > 0) ...[
                    _Chip(
                      icon: Icons.schedule_rounded,
                      label: '${proposal.durationDays}j',
                      isLight: isSelected,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (proposal.priceEur > 0)
                    _Chip(
                      icon: Icons.euro_rounded,
                      label: '${proposal.priceEur}€',
                      isLight: isSelected,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLight;

  const _Chip({required this.icon, required this.label, this.isLight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLight
            ? ColorName.surface.withValues(alpha: 0.2)
            : ColorName.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isLight ? ColorName.surface : ColorName.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isLight ? ColorName.surface : ColorName.primary,
            ),
          ),
        ],
      ),
    );
  }
}
