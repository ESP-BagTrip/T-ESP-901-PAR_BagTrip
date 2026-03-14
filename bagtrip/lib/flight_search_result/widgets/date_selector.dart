import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flight_search_result/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatelessWidget {
  final int selectedDateIndex;
  final DateTime departureDate;
  final DateTime? returnDate;
  final List<Flight> flights;

  const DateSelector({
    super.key,
    required this.selectedDateIndex,
    required this.departureDate,
    this.returnDate,
    required this.flights,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375; // iPhone SE width is ~375

    // Generate dates: -1 day, selected date, +1 day
    final dates = [
      departureDate.subtract(const Duration(days: 1)),
      departureDate,
      departureDate.add(const Duration(days: 1)),
    ];

    // Format dates - use shorter format on small screens
    final dateFormatter = DateFormat(
      isSmallScreen ? 'EEE\nd\nMMM' : 'EEE, d MMM',
      Localizations.localeOf(context).toString(),
    );

    // For small screens, format dates with line breaks manually
    final formattedDates =
        dates.map((date) {
          if (isSmallScreen) {
            final dayOfWeek = DateFormat(
              'EEE',
              Localizations.localeOf(context).toString(),
            ).format(date);
            final day = date.day.toString();
            final month = DateFormat(
              'MMM',
              Localizations.localeOf(context).toString(),
            ).format(date);
            return '$dayOfWeek\n$day\n$month';
          } else {
            return dateFormatter.format(date);
          }
        }).toList();

    // Calculate minimum price for each date
    final prices =
        dates.map((date) {
          // Filter flights by date (compare year, month, day)
          final flightsForDate =
              flights.where((flight) {
                if (flight.departureDateTime == null) return false;
                final flightDate = flight.departureDateTime!;
                return flightDate.year == date.year &&
                    flightDate.month == date.month &&
                    flightDate.day == date.day;
              }).toList();

          if (flightsForDate.isEmpty) {
            // If no flights for this date, use minimum price from all flights as approximation
            if (flights.isEmpty) return '';
            final minPrice = flights
                .map((f) => f.price)
                .reduce((a, b) => a < b ? a : b);
            return '${minPrice.toStringAsFixed(0)} €';
          }

          final minPrice = flightsForDate
              .map((f) => f.price)
              .reduce((a, b) => a < b ? a : b);
          return '${minPrice.toStringAsFixed(0)} €';
        }).toList();

    final iconSize = isSmallScreen ? 40.0 : 50.0;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.large16,
              border: Border.all(color: ColorName.primarySoftLight),
              boxShadow: [
                BoxShadow(
                  color: ColorName.primary.withValues(alpha: 0.08),
                  offset: const Offset(0, 4),
                  blurRadius: 6,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: ColorName.primary.withValues(alpha: 0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  spreadRadius: -1,
                ),
              ],
            ),
            child: Row(
              children: [
                ...formattedDates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final dateStr = entry.value;
                  return _buildDateCard(
                    context,
                    dateStr,
                    prices[index],
                    isSelected: index == selectedDateIndex,
                    isSmallScreen: isSmallScreen,
                    onTap: () {
                      if (context.mounted) {
                        context.read<FlightSearchResultBloc>().add(
                          SelectDate(index),
                        );
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? AppSpacing.space4 : AppSpacing.space8),
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.large16,
            border: Border.all(color: ColorName.primarySoftLight),
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.08),
                offset: const Offset(0, 4),
                blurRadius: 6,
                spreadRadius: -1,
              ),
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
                blurRadius: 4,
                spreadRadius: -1,
              ),
            ],
          ),
          child: Icon(
            Icons.calendar_today,
            color: ColorName.secondary,
            size: isSmallScreen ? 18 : 20,
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard(
    BuildContext context,
    String date,
    String price, {
    bool isSelected = false,
    bool isSmallScreen = false,
    VoidCallback? onTap,
  }) {
    final dateParts = date.split('\n');
    final isMultiLine = dateParts.length > 1;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.all(isSmallScreen ? 2 : AppSpacing.space4),
          padding: EdgeInsets.all(isSmallScreen ? 6 : AppSpacing.space8),
          decoration: BoxDecoration(
            color: isSelected ? ColorName.secondary : Colors.transparent,
            borderRadius: AppRadius.large16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isMultiLine) ...[
                // Format: EEE\n d\n MMM
                Text(
                  dateParts[0], // Day of week (ven.)
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.surface : ColorName.primary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  dateParts[1], // Day number (16)
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.surface : ColorName.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  dateParts[2], // Month (janv.)
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.surface : ColorName.primary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else ...[
                // Format: EEE, d MMM
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.surface : ColorName.primary,
                  ),
                  child: Text(
                    date,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (price.isNotEmpty) ...[
                SizedBox(height: isSmallScreen ? 2 : 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.surface : ColorName.primary,
                  ),
                  child: Text(
                    price,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
