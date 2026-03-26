import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/widgets/traveler_stepper.dart';
import 'package:flutter/material.dart';

/// Shows a bottom sheet with a [TravelerStepper] to edit the traveler count.
///
/// Returns the new count or `null` if dismissed.
Future<int?> showTravelersEditSheet({
  required BuildContext context,
  required int currentValue,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TravelersEditContent(currentValue: currentValue),
  );
}

class _TravelersEditContent extends StatefulWidget {
  final int currentValue;

  const _TravelersEditContent({required this.currentValue});

  @override
  State<_TravelersEditContent> createState() => _TravelersEditContentState();
}

class _TravelersEditContentState extends State<_TravelersEditContent> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            l10n.editTripTravelers,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorName.primaryTrueDark,
            ),
          ),
          const SizedBox(height: AppSpacing.space32),
          TravelerStepper(
            value: _count,
            onChanged: (v) => setState(() => _count = v),
          ),
          const SizedBox(height: AppSpacing.space32),
          Padding(
            padding: AppSpacing.horizontalSpace24,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_count),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.saveButton),
              ),
            ),
          ),
          const SafeArea(
            top: false,
            child: SizedBox(height: AppSpacing.space16),
          ),
        ],
      ),
    );
  }
}
