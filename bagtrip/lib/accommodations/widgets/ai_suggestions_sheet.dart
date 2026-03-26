import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/widgets/hotel_search_sheet.dart';
import 'package:bagtrip/accommodations/widgets/manual_accommodation_form.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiSuggestionsSheet extends StatelessWidget {
  final String tripId;
  final List<Map<String, dynamic>> suggestions;

  const AiSuggestionsSheet({
    super.key,
    required this.tripId,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (sheetContext, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.accommodationAiSuggestTitle,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(sheetContext).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: suggestions.length + 1,
                itemBuilder: (_, index) {
                  if (index == suggestions.length) {
                    // Disclaimer
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        l10n.accommodationAiDisclaimer,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  final s = suggestions[index];
                  final type = s['type'] as String? ?? 'OTHER';
                  final name = s['name'] as String? ?? '';
                  final neighborhood = s['neighborhood'] as String? ?? '';
                  final priceRange = s['priceRange'] as String? ?? '';
                  final currency = s['currency'] as String? ?? 'EUR';
                  final reason = s['reason'] as String? ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).cardTheme.color ??
                          Theme.of(context).colorScheme.surface,
                      borderRadius: AppRadius.large16,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge type
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ColorName.primary.withValues(alpha: 0.1),
                                borderRadius: AppRadius.medium8,
                              ),
                              child: Text(
                                _typeLabel(type, l10n),
                                style: const TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: ColorName.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (priceRange.isNotEmpty)
                              Text(
                                '$priceRange $currency/${l10n.accommodationNights}',
                                style: const TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: ColorName.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Name
                        Text(
                          name,
                          style: TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),

                        // Neighborhood
                        if (neighborhood.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: ColorName.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                neighborhood,
                                style: const TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 13,
                                  color: ColorName.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Reason
                        if (reason.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: FontFamily.b612,
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<AccommodationBloc>(),
                                      child: HotelSearchSheet(tripId: tripId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.search, size: 16),
                                label: Text(
                                  l10n.accommodationSearchInArea,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<AccommodationBloc>(),
                                      child: ManualAccommodationForm(
                                        tripId: tripId,
                                        prefill: {
                                          'name': name,
                                          'neighborhood': neighborhood,
                                          'currency': currency,
                                        },
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: Text(
                                  l10n.accommodationAddManually,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type, AppLocalizations l10n) {
    return switch (type) {
      'HOTEL' => l10n.accommodationTypeHotel,
      'AIRBNB' => l10n.accommodationTypeAirbnb,
      'HOSTEL' => l10n.accommodationTypeHostel,
      'GUESTHOUSE' => l10n.accommodationTypeGuesthouse,
      'CAMPING' => l10n.accommodationTypeCamping,
      'RESORT' => l10n.accommodationTypeResort,
      _ => l10n.accommodationTypeOther,
    };
  }
}
