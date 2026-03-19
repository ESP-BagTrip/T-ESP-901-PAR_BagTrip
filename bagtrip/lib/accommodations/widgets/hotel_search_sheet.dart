import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/widgets/manual_accommodation_form.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HotelSearchSheet extends StatefulWidget {
  final String tripId;
  final String? initialCityCode;

  const HotelSearchSheet({
    super.key,
    required this.tripId,
    this.initialCityCode,
  });

  @override
  State<HotelSearchSheet> createState() => _HotelSearchSheetState();
}

class _HotelSearchSheetState extends State<HotelSearchSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCityCode != null) {
      _searchCtrl.text = widget.initialCityCode!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final code = _searchCtrl.text.trim().toUpperCase();
    if (code.length >= 3) {
      context.read<AccommodationBloc>().add(SearchHotels(cityCode: code));
    }
  }

  void _selectHotel(Map<String, dynamic> hotel) {
    Navigator.of(context).pop();
    final name = hotel['name'] as String? ?? '';
    final address = hotel['address'] is Map
        ? (hotel['address'] as Map)['countryCode'] as String? ?? ''
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AccommodationBloc>(),
        child: ManualAccommodationForm(
          tripId: widget.tripId,
          isEstimatedPrice: true,
          prefill: {'name': name, 'address': address},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (sheetContext, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar + title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          sheetContext,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.accommodationSearchHotels,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(sheetContext).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'PAR, LON, NYC...',
                            labelText: l10n.accommodationSearchInArea,
                            prefixIcon: const Icon(Icons.search),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _search,
                        child: const Icon(Icons.search),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Results
            Expanded(
              child: BlocBuilder<AccommodationBloc, AccommodationState>(
                builder: (context, state) {
                  if (state is HotelSearchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is HotelSearchLoaded) {
                    final hotels = state.hotels;
                    if (hotels.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.accommodationEmptyTitle,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: hotels.length,
                      itemBuilder: (_, index) {
                        final hotel = hotels[index];
                        final name = hotel['name'] as String? ?? 'Hotel';
                        final hotelId = hotel['hotelId'] as String? ?? '';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.large16,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.hotel,
                              color: ColorName.primary,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontFamily: FontFamily.b612,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              hotelId,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            onTap: () => _selectHotel(hotel),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
