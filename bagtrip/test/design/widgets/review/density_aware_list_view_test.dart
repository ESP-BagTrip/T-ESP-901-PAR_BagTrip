import 'package:bagtrip/design/subpage_state.dart';
import 'package:bagtrip/design/widgets/review/density_aware_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(height: 600, child: child)),
  );

  group('DensityAwareListView', () {
    testWidgets('sparse uses 24pt outer padding', (tester) async {
      await tester.pumpWidget(
        wrap(
          DensityAwareListView<String>(
            density: HeroDensity.sparse,
            items: const ['A', 'B'],
            itemBuilder: (_, item, _) =>
                SizedBox(height: 100, child: Text(item)),
          ),
        ),
      );
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect((listView.padding as EdgeInsets).left, 24);
    });

    testWidgets('dense uses 12pt outer padding', (tester) async {
      await tester.pumpWidget(
        wrap(
          DensityAwareListView<String>(
            density: HeroDensity.dense,
            items: const ['A', 'B'],
            itemBuilder: (_, item, _) =>
                SizedBox(height: 100, child: Text(item)),
          ),
        ),
      );
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect((listView.padding as EdgeInsets).left, 12);
    });

    testWidgets('renders leading and trailing slots', (tester) async {
      await tester.pumpWidget(
        wrap(
          DensityAwareListView<String>(
            density: HeroDensity.sparse,
            items: const ['A'],
            leading: const Text('LEADING'),
            trailing: const Text('TRAILING'),
            itemBuilder: (_, item, _) => Text(item),
          ),
        ),
      );
      expect(find.text('LEADING'), findsOneWidget);
      expect(find.text('TRAILING'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('calls itemBuilder with correct indices', (tester) async {
      final seenIndices = <int>[];
      await tester.pumpWidget(
        wrap(
          DensityAwareListView<String>(
            density: HeroDensity.dense,
            items: const ['A', 'B', 'C'],
            leading: const Text('LEADING'),
            itemBuilder: (_, item, index) {
              seenIndices.add(index);
              return Text('$item-$index');
            },
          ),
        ),
      );
      expect(seenIndices, containsAll([0, 1, 2]));
      expect(find.text('A-0'), findsOneWidget);
      expect(find.text('B-1'), findsOneWidget);
      expect(find.text('C-2'), findsOneWidget);
    });

    testWidgets('bottom padding reserves footer space', (tester) async {
      await tester.pumpWidget(
        wrap(
          DensityAwareListView<String>(
            density: HeroDensity.dense,
            items: const ['A'],
            footerReserved: 120,
            itemBuilder: (_, item, _) => Text(item),
          ),
        ),
      );
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(
        (listView.padding as EdgeInsets).bottom,
        12 + 120, // dense outer + footer reserved
      );
    });
  });
}
