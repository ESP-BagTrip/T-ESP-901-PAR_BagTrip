import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/flight_search/models/airport_type.dart';
import 'package:bagtrip/flight_search/widgets/airport_search_field.dart';
import 'package:flutter/material.dart';

class AirportField extends StatelessWidget {
  final IconData icon;
  final String label;
  final AirportType type;
  final Map<String, dynamic>? value;
  final Function(Map<String, dynamic>?, AirportType) onSelected;

  const AirportField({
    super.key,
    required this.icon,
    required this.label,
    required this.type,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(icon, color: ColorName.secondary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: ColorName.secondary,
                  fontFamily: FontFamily.b612,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              AirportSearchField(
                type: type,
                hintText: type.getHintText(context),
                initialValue: value,
                onSelected: onSelected,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primary,
                  fontFamily: FontFamily.b612,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
