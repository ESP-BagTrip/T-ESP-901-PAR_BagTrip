import 'package:bagtrip/accommodations/bloc/accommodation_bloc.dart';
import 'package:bagtrip/accommodations/widgets/hotel_search_sheet.dart';
import 'package:bagtrip/accommodations/widgets/manual_accommodation_form.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/form/form_option_tile.dart';
import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddAccommodationSheet extends StatelessWidget {
  final String tripId;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;
  final String? destinationIata;

  const AddAccommodationSheet({
    super.key,
    required this.tripId,
    this.tripStartDate,
    this.tripEndDate,
    this.destinationIata,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ItemFormScaffold(
      title: l10n.accommodationAddTitle,
      fields: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormOptionTile(
            icon: Icons.edit_rounded,
            title: l10n.accommodationAddManually,
            subtitle: l10n.accommodationAddManuallySubtitle,
            onTap: () {
              Navigator.of(context).pop();
              showItemFormSheet<void>(
                context: context,
                child: BlocProvider.value(
                  value: context.read<AccommodationBloc>(),
                  child: ManualAccommodationForm(
                    tripId: tripId,
                    tripStartDate: tripStartDate,
                    tripEndDate: tripEndDate,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.space12),
          FormOptionTile(
            icon: Icons.search_rounded,
            title: l10n.accommodationSearchHotels,
            subtitle: l10n.accommodationSearchHotelsSubtitle,
            onTap: () {
              Navigator.of(context).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: context.read<AccommodationBloc>(),
                  child: HotelSearchSheet(
                    tripId: tripId,
                    initialCityCode: destinationIata,
                    tripStartDate: tripStartDate,
                    tripEndDate: tripEndDate,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      actions: const [],
    );
  }
}
