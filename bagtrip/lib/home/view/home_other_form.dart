import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class HomeOtherForm extends StatelessWidget {
  const HomeOtherForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 64, color: ColorName.primarySoftLight),
            SizedBox(height: 16),
            Text(
              'Autres services bientôt disponibles',
              style: TextStyle(
                fontSize: 16,
                fontFamily: FontFamily.b612,
                color: ColorName.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
