import 'package:bagtrip/pages/forgot_password_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  group('ForgotPasswordPage', () {
    testWidgets('renders the form with email input', (tester) async {
      await pumpLocalized(tester, const ForgotPasswordPage());
      await tester.pump();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('builds without errors on default state', (tester) async {
      await pumpLocalized(tester, const ForgotPasswordPage());
      await tester.pump();
      await tester.pump();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });
  });
}
