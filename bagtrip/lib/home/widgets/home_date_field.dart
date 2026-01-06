import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeDateField extends StatelessWidget {
  final String hint;
  final DateTime? value;
  final VoidCallback onTap;
  final bool hasError;

  const HomeDateField({
    super.key,
    required this.hint,
    this.value,
    required this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        value != null ? DateFormat('d MMM yyyy').format(value!) : hint,
        style: TextStyle(
          fontSize: 18, // Large text as in the image
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.b612,
          color: value != null ? ColorName.primary : const Color(0xFF9AA6AC),
        ),
      ),
    );
  }
}
