import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/flightSearchResult/bloc/flight_search_result_bloc.dart';
import 'package:bagtrip/gen/colors.gen.dart';

class DateSelector extends StatelessWidget {
  final int selectedDateIndex;

  const DateSelector({super.key, required this.selectedDateIndex});

  @override
  Widget build(BuildContext context) {
    // Ideally this data should come from the Bloc/State or a model,
    // but for now we keep it here as in the original code.
    final dates = [
      {'date': 'Lun, 2 sept', 'price': '186 €'},
      {'date': 'Mar, 3 sept', 'price': '186 €'},
      {'date': 'Mer, 4 sept', 'price': '186 €'},
    ];

    return SizedBox(
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: ColorName.primaryLight,
                borderRadius: AppRadius.large16,
              ),
              child: Row(
                children: [
                  ...dates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildDateCard(
                      context,
                      item['date'] ?? '',
                      item['price'] ?? '',
                      isSelected: index == selectedDateIndex,
                      onTap: () {
                        context.read<FlightSearchResultBloc>().add(
                          SelectDate(index),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: ColorName.primaryLight,
              borderRadius: AppRadius.large16,
            ),
            child: const Icon(Icons.calendar_today, color: ColorName.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(
    BuildContext context,
    String date,
    String price, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: AppSpacing.allEdgeInsetSpace8,
          decoration: BoxDecoration(
            color: isSelected ? ColorName.secondary : ColorName.primaryLight,
            borderRadius: AppRadius.large16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : ColorName.primary,
                ),
                child: Text(date),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : ColorName.primary,
                ),
                child: Text(price),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
