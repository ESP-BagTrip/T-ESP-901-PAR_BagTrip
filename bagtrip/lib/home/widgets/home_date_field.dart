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
    return TextField(
      controller: TextEditingController(
        text: value != null ? DateFormat('dd/MM/yyyy').format(value!) : '',
      ),
      readOnly: true,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintStyle: TextStyle(
          fontSize: 13,
          fontFamily: FontFamily.b612,
          color: hasError ? ColorName.error : ColorName.primary,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
        hintText: hint,
      ),
      onTap: onTap,
    );
  }
}
