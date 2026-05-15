import 'package:bagtrip/design/widgets/form/pill_segmented_control.dart';
import 'package:flutter/material.dart';

export 'pill_segmented_control.dart';

/// Two-option [PillSegmentedControl] alias (flight type, etc.).
class PillDualSegment<T> extends StatelessWidget {
  const PillDualSegment({
    super.key,
    required this.value,
    required this.onChanged,
    required this.segments,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<PillDualSegmentOption<T>> segments;

  @override
  Widget build(BuildContext context) {
    assert(segments.length == 2, 'PillDualSegment supports exactly 2 options');
    return PillSegmentedControl<T>(
      value: value,
      onChanged: onChanged,
      segments: [
        for (final s in segments)
          PillSegmentOption(value: s.value, label: s.label),
      ],
    );
  }
}

class PillDualSegmentOption<T> {
  const PillDualSegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}
