import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/profile/widgets/logout_button.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LogoutRequested());
    registerFallbackValue(AuthInitial());
  });

  setUp(() {
    mockBloc = _MockAuthBloc();
    when(() => mockBloc.state).thenReturn(AuthInitial());
    whenListen(
      mockBloc,
      const Stream<AuthState>.empty(),
      initialState: AuthInitial(),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await pumpLocalized(
      tester,
      SizedBox(
        width: 800,
        height: 200,
        child: BlocProvider<AuthBloc>.value(
          value: mockBloc,
          child: const LogoutButton(),
        ),
      ),
    );
    await tester.pump();
  }

  group('LogoutButton', () {
    testWidgets('renders with InkWell tappable area', (tester) async {
      await pump(tester);
      expect(find.byType(LogoutButton), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('renders logout icon', (tester) async {
      await pump(tester);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });
}
