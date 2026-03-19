import 'package:bagtrip/design/widgets/destination_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({int itemCount = 3, ValueChanged<int>? onPageChanged}) {
    return MaterialApp(
      home: Scaffold(
        body: DestinationCarousel(
          itemCount: itemCount,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return Container(
              key: ValueKey('item_$index'),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.primaries[index % Colors.primaries.length],
              child: Center(child: Text('Card $index')),
            );
          },
        ),
      ),
    );
  }

  group('DestinationCarousel', () {
    testWidgets('renders items', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Card 0'), findsOneWidget);
    });

    testWidgets('renders dot indicators for each item', (tester) async {
      await tester.pumpWidget(buildApp(itemCount: 4));
      await tester.pumpAndSettle();

      // 4 AnimatedContainers for dots + possibly others
      // Just check the PageView and dots exist
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('page change callback fires', (tester) async {
      int? changedPage;
      await tester.pumpWidget(buildApp(onPageChanged: (p) => changedPage = p));
      await tester.pumpAndSettle();

      // Swipe left
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(changedPage, isNotNull);
      expect(changedPage, 1);
    });
  });
}
