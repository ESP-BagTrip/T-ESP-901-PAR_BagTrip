import 'package:bagtrip/components/adaptive/adaptive_time_picker.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flight_search_result/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FilterDialog extends StatefulWidget {
  final FlightSearchResultLoaded state;

  const FilterDialog({super.key, required this.state});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String? _selectedPriceSort;
  String? _selectedAirline;
  bool? _cabinBagIncluded;
  bool? _checkedBagIncluded;
  TimeOfDay? _departureTimeBefore;
  TimeOfDay? _departureTimeAfter;

  @override
  void initState() {
    super.initState();
    _selectedPriceSort = widget.state.priceSort;
    _selectedAirline = widget.state.selectedAirline;
    _cabinBagIncluded = widget.state.cabinBagIncluded;
    _checkedBagIncluded = widget.state.checkedBagIncluded;
    _departureTimeBefore = widget.state.departureTimeBefore;
    _departureTimeAfter = widget.state.departureTimeAfter;
  }

  List<String> _getAvailableAirlines() {
    final airlines = <String>{};
    for (final flight in widget.state.flights) {
      if (flight.airline != null && flight.airline!.isNotEmpty) {
        airlines.add(flight.airline!);
      }
    }
    return airlines.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final availableAirlines = _getAvailableAirlines();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: AppSpacing.allEdgeInsetSpace24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtres',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColorName.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price sort
                    const Text(
                      'Prix',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorName.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPriceOption(
                            'lowest',
                            'Prix le plus bas',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        Expanded(
                          child: _buildPriceOption(
                            'highest',
                            'Prix le plus haut',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space24),

                    // Airline filter
                    const Text(
                      'Compagnie aérienne',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorName.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    if (availableAirlines.isEmpty)
                      const Text(
                        'Aucune compagnie disponible',
                        style: TextStyle(fontSize: 14, color: AppColors.hint),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAirline,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(child: Text('Toutes')),
                          ...availableAirlines.map(
                            (airline) => DropdownMenuItem<String>(
                              value: airline,
                              child: Text(airline),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAirline = value;
                          });
                        },
                      ),
                    const SizedBox(height: AppSpacing.space24),

                    // Baggage filters
                    const Text(
                      'Bagages',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorName.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    CheckboxListTile.adaptive(
                      title: Text(
                        AppLocalizations.of(context)!.filterCabinBagIncluded,
                      ),
                      value: _cabinBagIncluded ?? false,
                      onChanged: (value) {
                        setState(() {
                          _cabinBagIncluded = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile.adaptive(
                      title: Text(
                        AppLocalizations.of(context)!.filterCheckedBagIncluded,
                      ),
                      value: _checkedBagIncluded ?? false,
                      onChanged: (value) {
                        setState(() {
                          _checkedBagIncluded = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.space24),

                    // Departure time filters
                    const Text(
                      'Heure de départ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorName.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeButton(
                            'Avant',
                            _departureTimeBefore,
                            (time) =>
                                setState(() => _departureTimeBefore = time),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        Expanded(
                          child: _buildTimeButton(
                            'Après',
                            _departureTimeAfter,
                            (time) =>
                                setState(() => _departureTimeAfter = time),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedPriceSort = null;
                        _selectedAirline = null;
                        _cabinBagIncluded = false;
                        _checkedBagIncluded = false;
                        _departureTimeBefore = null;
                        _departureTimeAfter = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.filterReset),
                  ),
                ),
                const SizedBox(width: AppSpacing.space16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<FlightSearchResultBloc>().add(
                        ApplyFilters(
                          priceSort: _selectedPriceSort,
                          selectedAirline: _selectedAirline,
                          cabinBagIncluded: _cabinBagIncluded == true
                              ? true
                              : null,
                          checkedBagIncluded: _checkedBagIncluded == true
                              ? true
                              : null,
                          departureTimeBefore: _departureTimeBefore,
                          departureTimeAfter: _departureTimeAfter,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorName.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Appliquer',
                      style: TextStyle(color: AppColors.surface),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceOption(String value, String label) {
    final isSelected = _selectedPriceSort == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriceSort = isSelected ? null : value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? ColorName.secondary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ColorName.secondary
                : ColorName.primarySoftLight,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.surface : ColorName.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(
    String label,
    TimeOfDay? selectedTime,
    Function(TimeOfDay?) onTimeSelected,
  ) {
    return GestureDetector(
      onLongPress: selectedTime != null
          ? () {
              // Long press to clear
              onTimeSelected(null);
            }
          : null,
      child: OutlinedButton(
        onPressed: () async {
          final time = await showAdaptiveTimePicker(
            context: context,
            initialTime: selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
          );
          if (time != null) {
            onTimeSelected(time);
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              selectedTime != null
                  ? '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'
                  : label,
            ),
            if (selectedTime != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onTimeSelected(null),
                child: const Icon(Icons.close, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
