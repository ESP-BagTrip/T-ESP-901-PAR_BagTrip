import 'package:bagtrip/design/widgets/review/bottom_sheet_scaffold.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/trip_detail/widgets/completion_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_widget.dart';

void main() {
  group('ReviewBottomSheetScaffold', () {
    testWidgets('renders title, subtitle, body, primary CTA', (tester) async {
      await pumpLocalized(
        tester,
        const ReviewBottomSheetScaffold(
          title: 'Add flight',
          subtitle: 'TOKYO',
          primaryLabel: 'Save',
          child: Text('form body'),
        ),
      );
      expect(find.text('Add flight'), findsOneWidget);
      expect(find.text('TOKYO'), findsOneWidget);
      expect(find.text('form body'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('invokes onPrimary when primary tapped', (tester) async {
      var tapped = false;
      await pumpLocalized(
        tester,
        ReviewBottomSheetScaffold(
          title: 'Add flight',
          primaryLabel: 'Save',
          onPrimary: () => tapped = true,
          child: const SizedBox.shrink(),
        ),
      );
      await tester.tap(find.text('Save'));
      expect(tapped, isTrue);
    });

    testWidgets('shows secondary action when label/callback provided', (
      tester,
    ) async {
      var deleted = false;
      await pumpLocalized(
        tester,
        ReviewBottomSheetScaffold(
          title: 'Edit',
          primaryLabel: 'Save',
          secondaryLabel: 'Delete',
          isSecondaryDestructive: true,
          onSecondary: () => deleted = true,
          child: const SizedBox.shrink(),
        ),
      );
      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      expect(deleted, isTrue);
    });

    testWidgets('disables primary when onPrimary is null and not loading', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const ReviewBottomSheetScaffold(
          title: 'Edit',
          primaryLabel: 'Save',
          child: SizedBox.shrink(),
        ),
      );
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows spinner when isSubmitting=true', (tester) async {
      await pumpLocalized(
        tester,
        ReviewBottomSheetScaffold(
          title: 'Edit',
          primaryLabel: 'Save',
          isSubmitting: true,
          onPrimary: () {},
          child: const SizedBox.shrink(),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('PanelFooterCta', () {
    testWidgets('renders child and is visible by default', (tester) async {
      late PanelFooterCtaController controller;
      await tester.pumpWidget(
        MaterialApp(
          home: _TickerHost(
            builder: (vsync) {
              controller = PanelFooterCtaController(vsync: vsync);
              return PanelFooterCta(
                controller: controller,
                child: const PillCtaButton(label: 'Save', onTap: null),
              );
            },
          ),
        ),
      );
      expect(find.text('Save'), findsOneWidget);
      expect(controller.animation.value, 1);
      controller.dispose();
    });

    testWidgets('show / hide drive the animation', (tester) async {
      late PanelFooterCtaController controller;
      await tester.pumpWidget(
        MaterialApp(
          home: _TickerHost(
            builder: (vsync) {
              controller = PanelFooterCtaController(vsync: vsync);
              return PanelFooterCta(
                controller: controller,
                child: const PillCtaButton(label: 'Save', onTap: null),
              );
            },
          ),
        ),
      );
      controller.hide();
      await tester.pumpAndSettle();
      expect(controller.animation.value, lessThan(0.1));

      controller.show();
      await tester.pumpAndSettle();
      expect(controller.animation.value, greaterThan(0.9));
      controller.dispose();
    });

    testWidgets(
      'handleScrollNotification scroll-down hides and scroll-up shows',
      (tester) async {
        late PanelFooterCtaController controller;
        final scrollKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: _TickerHost(
              builder: (vsync) {
                controller = PanelFooterCtaController(vsync: vsync);
                return NotificationListener<ScrollNotification>(
                  onNotification: controller.handleScrollNotification,
                  child: ListView(
                    key: scrollKey,
                    children: List.generate(
                      40,
                      (i) => SizedBox(height: 80, child: Text('row-$i')),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        expect(controller.animation.value, 1);

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(controller.animation.value, lessThan(0.1));

        await tester.drag(find.byType(ListView), const Offset(0, 200));
        await tester.pumpAndSettle();
        expect(controller.animation.value, greaterThan(0.9));
        controller.dispose();
      },
    );
  });

  group('CompletionRing', () {
    testWidgets('renders clamped percentage text', (tester) async {
      await pumpLocalized(tester, const CompletionRing(percentage: 73));
      await tester.pumpAndSettle();
      expect(find.text('73%'), findsOneWidget);
    });

    testWidgets('clamps values above 100', (tester) async {
      await pumpLocalized(tester, const CompletionRing(percentage: 140));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('clamps values below 0', (tester) async {
      await pumpLocalized(tester, const CompletionRing(percentage: -5));
      await tester.pumpAndSettle();
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('fires onTap when provided', (tester) async {
      var tapped = false;
      await pumpLocalized(
        tester,
        CompletionRing(percentage: 50, onTap: () => tapped = true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CompletionRing));
      expect(tapped, isTrue);
    });
  });
}

class _TickerHost extends StatefulWidget {
  const _TickerHost({required this.builder});
  final Widget Function(TickerProvider vsync) builder;

  @override
  State<_TickerHost> createState() => _TickerHostState();
}

class _TickerHostState extends State<_TickerHost>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) => Material(child: widget.builder(this));
}
