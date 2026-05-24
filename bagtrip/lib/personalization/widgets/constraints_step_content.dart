import 'package:bagtrip/design/personalization_colors.dart';
import 'package:flutter/material.dart';

class ConstraintsStepContent extends StatelessWidget {
  const ConstraintsStepContent({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final void Function(String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value ?? '')
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: (value ?? '').length),
        ),
      onChanged: onChanged,
      maxLines: 4,
      decoration: InputDecoration(
        hintText:
            'Ex: pas de destination asiatique, dates fixes du 10 au 20 avril',
        hintStyle: TextStyle(
          color: PersonalizationColors.textSecondary.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: PersonalizationColors.textSecondary,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: PersonalizationColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: PersonalizationColors.textPrimary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(
        fontSize: 14,
        color: PersonalizationColors.textPrimary,
      ),
    );
  }
}
