import 'package:bagtrip/design/widgets/ai_suggestion_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    String? imageUrl,
    String? matchReason,
    int? durationDays,
    int? priceEur,
    List<String>? badges,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AiSuggestionCard(
            destination: 'Paris',
            country: 'France',
            imageUrl: imageUrl,
            matchReason: matchReason,
            durationDays: durationDays,
            priceEur: priceEur,
            badges: badges,
            isSelected: isSelected,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  group('AiSuggestionCard', () {
    testWidgets('renders destination and country', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Paris'), findsOneWidget);
      expect(find.text('France'), findsOneWidget);
    });

    testWidgets('renders placeholder when no image', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.byIcon(Icons.landscape_rounded), findsOneWidget);
    });

    testWidgets('renders match reason when provided', (tester) async {
      await tester.pumpWidget(buildApp(matchReason: 'Perfect for summer'));

      expect(find.text('Perfect for summer'), findsOneWidget);
    });

    testWidgets('renders duration and price chips', (tester) async {
      await tester.pumpWidget(buildApp(durationDays: 5, priceEur: 800));

      expect(find.text('5d'), findsOneWidget);
      expect(find.text('800€'), findsOneWidget);
    });

    testWidgets('renders badges', (tester) async {
      await tester.pumpWidget(
        buildApp(badges: ['Beach', 'Mountains', 'Culture']),
      );

      expect(find.text('Beach'), findsOneWidget);
      expect(find.text('Mountains'), findsOneWidget);
      expect(find.text('Culture'), findsOneWidget);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildApp(onTap: () => tapped = true));

      await tester.tap(find.byType(AiSuggestionCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('selected state changes decoration', (tester) async {
      await tester.pumpWidget(buildApp(isSelected: true));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNotNull);
    });
  });
}
