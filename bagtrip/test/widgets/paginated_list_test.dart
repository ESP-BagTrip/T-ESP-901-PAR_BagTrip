import 'package:bagtrip/components/paginated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginatedList', () {
    testWidgets('renders items correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedList<String>(
              items: const ['Item 1', 'Item 2', 'Item 3'],
              hasMore: false,
              isLoadingMore: false,
              onLoadMore: () {},
              itemBuilder: (context, item, index) =>
                  ListTile(title: Text(item)),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoadingMore is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedList<String>(
              items: const ['Item 1'],
              hasMore: true,
              isLoadingMore: true,
              onLoadMore: () {},
              itemBuilder: (context, item, index) =>
                  ListTile(title: Text(item)),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show loading indicator when not loading more', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedList<String>(
              items: const ['Item 1'],
              hasMore: true,
              isLoadingMore: false,
              onLoadMore: () {},
              itemBuilder: (context, item, index) =>
                  ListTile(title: Text(item)),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows emptyWidget when items is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedList<String>(
              items: const [],
              hasMore: false,
              isLoadingMore: false,
              onLoadMore: () {},
              itemBuilder: (context, item, index) =>
                  ListTile(title: Text(item)),
              emptyWidget: const Text('No items'),
            ),
          ),
        ),
      );

      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('renders grouped list with section headers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedList<String>(
              items: const ['A1', 'A2', 'B1'],
              hasMore: false,
              isLoadingMore: false,
              onLoadMore: () {},
              itemBuilder: (context, item, index) =>
                  ListTile(title: Text(item)),
              groupBy: (items) {
                final Map<String, List<String>> grouped = {};
                for (final item in items) {
                  final key = item.substring(0, 1);
                  grouped.putIfAbsent(key, () => []).add(item);
                }
                return grouped;
              },
              sectionHeaderBuilder: (_, key) => Text('Section $key'),
            ),
          ),
        ),
      );

      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('Section B'), findsOneWidget);
      expect(find.text('A1'), findsOneWidget);
      expect(find.text('A2'), findsOneWidget);
      expect(find.text('B1'), findsOneWidget);
    });
  });
}
