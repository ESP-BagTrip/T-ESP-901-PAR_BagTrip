import 'package:bagtrip/components/custom_calendar_picker.dart';
import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Two date cards side by side: DEPART and RETURN (maquette style).
class ManualFlightDateCards extends StatelessWidget {
  const ManualFlightDateCards({super.key, required this.state});

  final FlightSearchLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRoundTrip = state.tripTypeIndex == 1;

    return Row(
      children: [
        Expanded(
          child: _DateCard(
            label: l10n.departLabel.toUpperCase(),
            date: state.departureDate,
            onTap: () => _pickDepartureDate(context),
          ),
        ),
        const SizedBox(width: 12),
        if (isRoundTrip)
          Expanded(
            child: _DateCard(
              label: l10n.returnLabel.toUpperCase(),
              date: state.returnDate,
              onTap: () => _pickReturnDate(context),
            ),
          ),
      ],
    );
  }

  Future<void> _pickDepartureDate(BuildContext context) async {
    final bloc = context.read<FlightSearchBloc>();
    if (state.tripTypeIndex == 1) {
      final picked = await showCustomCalendarPicker(
        context: context,
        initialDate: state.departureDate ?? DateTime.now(),
        initialEndDate: state.returnDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
        isRangeSelection: true,
      );
      if (picked != null && context.mounted) {
        bloc.add(SetDepartureDate(picked.startDate));
        if (picked.endDate != null) {
          bloc.add(SetReturnDate(picked.endDate!));
        }
      }
    } else {
      final picked = await showCustomCalendarPicker(
        context: context,
        initialDate: state.departureDate ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
      );
      if (picked != null && context.mounted) {
        bloc.add(SetDepartureDate(picked.startDate));
      }
    }
  }

  Future<void> _pickReturnDate(BuildContext context) async {
    final bloc = context.read<FlightSearchBloc>();
    final picked = await showCustomCalendarPicker(
      context: context,
      initialDate: state.departureDate ?? DateTime.now(),
      initialEndDate: state.returnDate,
      firstDate: state.departureDate ?? DateTime.now(),
      lastDate: DateTime(2101),
      isRangeSelection: true,
    );
    if (picked != null && context.mounted) {
      bloc.add(SetDepartureDate(picked.startDate));
      if (picked.endDate != null) {
        bloc.add(SetReturnDate(picked.endDate!));
      }
    }
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayDate = date != null ? DateFormat('EEE d').format(date!) : null;
    final monthYear = date != null
        ? DateFormat('MMMM yyyy').format(date!)
        : null;

    const dateCardRadius = BorderRadius.all(Radius.circular(48));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: dateCardRadius,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ColorName.surface,
            borderRadius: dateCardRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: ColorName.primaryTrueDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ColorName.hint,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                dayDate ?? '—',
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: dayDate != null
                      ? ColorName.primaryTrueDark
                      : ColorName.hint,
                ),
              ),
              if (monthYear != null) ...[
                const SizedBox(height: 4),
                Text(
                  monthYear,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    color: ColorName.hint,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
