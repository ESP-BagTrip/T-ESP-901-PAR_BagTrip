import 'package:flutter/material.dart';

class PersonalizationLayoutGrid extends StatelessWidget {
  const PersonalizationLayoutGrid({
    super.key,
    required this.crossAxisCount,
    required this.children,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
  });

  final int crossAxisCount;
  final List<Widget> children;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  static List<List<Widget>> _chunked(List<Widget> list, int size) {
    final result = <List<Widget>>[];
    for (var i = 0; i < list.length; i += size) {
      result.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final rows = PersonalizationLayoutGrid._chunked(children, crossAxisCount);
    return Column(
      children: rows.asMap().entries.map((entry) {
        final isLast = entry.key == rows.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : mainAxisSpacing),
          child: Row(
            children: entry.value.asMap().entries.map((e) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: e.key < entry.value.length - 1
                        ? crossAxisSpacing
                        : 0,
                  ),
                  child: e.value,
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
