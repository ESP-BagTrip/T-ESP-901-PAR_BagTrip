import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class HomePriceField extends StatelessWidget {
  final Function(double?) onPriceChanged;

  const HomePriceField({super.key, required this.onPriceChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintStyle: const TextStyle(
          fontSize: 13,
          fontFamily: FontFamily.b612,
          color: Color(0xFF9AA6AC),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
        hintText: AppLocalizations.of(context)!.maxPriceHint,
      ),
      onChanged: (value) {
        if (value.isEmpty) {
          onPriceChanged(null);
          return;
        }
        final price = double.tryParse(value);
        onPriceChanged(price);
      },
    );
  }
}
