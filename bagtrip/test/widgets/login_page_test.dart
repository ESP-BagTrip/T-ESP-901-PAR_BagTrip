// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/pages/login_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_widget.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoginRequested(email: 'a@b', password: 'x'));
    registerFallbackValue(AuthInitial());
  });

  setUp(() {
    mockBloc = _MockAuthBloc();
  });

  Future<void> pump(WidgetTester tester, AuthState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(mockBloc, const Stream<AuthState>.empty(), initialState: seed);
    await pumpLocalized(
      tester,
      BlocProvider<AuthBloc>.value(value: mockBloc, child: const LoginPage()),
    );
    await tester.pump();
  }

  group('LoginPage', () {
    testWidgets('renders in login mode with AuthInitial', (tester) async {
      await pump(tester, AuthInitial());
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders in sign-up mode when isLoginMode is false', (
      tester,
    ) async {
      await pump(tester, AuthInitial(isLoginMode: false));
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders in loading state', (tester) async {
      await pump(tester, AuthLoading());
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('renders with AuthError state', (tester) async {
      await pump(
        tester,
        AuthError(error: const NetworkError('offline'), isLoginMode: true),
      );
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
