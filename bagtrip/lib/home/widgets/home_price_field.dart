import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class HomePriceField extends StatelessWidget {
  final Function(double) onPriceChanged;

  const HomePriceField({super.key, required this.onPriceChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      textAlignVertical: TextAlignVertical.center,
      decoration: const InputDecoration(
        hintStyle: TextStyle(
          fontSize: 13,
          fontFamily: FontFamily.b612,
          color: ColorName.primary,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
        hintText: 'Prix maximum (€)',
      ),
      onChanged: (value) {
        final price = double.tryParse(value) ?? 0.0;
        onPriceChanged(price);
      },
    );
  }
}
