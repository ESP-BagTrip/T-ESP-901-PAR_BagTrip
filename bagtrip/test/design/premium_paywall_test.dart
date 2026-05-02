import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/repositories/subscription_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/pump_widget.dart';

/// Renders the paywall as a body widget rather than a bottom sheet so the
/// test bypasses the modal route and inspects the actual content tree
/// directly. We don't need to validate the sheet plumbing here — that's
/// handled by Flutter — only that the paywall renders the right copy.
class _PaywallHost extends StatelessWidget {
  const _PaywallHost();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: PremiumPaywall()));
  }
}

void main() {
  late MockSubscriptionRepository mockRepo;

  setUp(() {
    mockRepo = MockSubscriptionRepository();
    if (getIt.isRegistered<SubscriptionRepository>()) {
      getIt.unregister<SubscriptionRepository>();
    }
    getIt.registerSingleton<SubscriptionRepository>(mockRepo);
  });

  tearDown(() {
    if (getIt.isRegistered<SubscriptionRepository>()) {
      getIt.unregister<SubscriptionRepository>();
    }
  });

  group('PremiumPaywall', () {
    testWidgets('shows the first feature page on initial render', (
      tester,
    ) async {
      await pumpLocalized(tester, const _PaywallHost());
      // First feature: AI without limits.
      expect(find.text('Plan without limits'), findsOneWidget);
      // CTA + disclaimer + price visible.
      expect(find.text('Try Premium'), findsOneWidget);
      expect(find.text('Cancel anytime'), findsOneWidget);
      expect(find.textContaining('9,99'), findsOneWidget);
    });

    testWidgets('swiping the PageView reveals the next feature', (
      tester,
    ) async {
      await pumpLocalized(tester, const _PaywallHost());
      expect(find.text('Travel together'), findsNothing);
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Travel together'), findsOneWidget);
    });

    testWidgets(
      'CTA renders alongside the price + disclaimer in a single column',
      (tester) async {
        await pumpLocalized(tester, const _PaywallHost());
        // Single CTA, single price, single disclaimer — no duplicates from a
        // re-render bug.
        expect(find.text('Try Premium'), findsOneWidget);
        expect(find.text('Cancel anytime'), findsOneWidget);
        expect(find.textContaining('9,99'), findsOneWidget);
      },
    );

    testWidgets(
      'renders an explicit close button so the user can dismiss without swipe',
      (tester) async {
        await pumpLocalized(tester, const _PaywallHost());
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      },
    );
  });
}
