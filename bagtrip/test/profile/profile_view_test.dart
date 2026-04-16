import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/profile/view/profile_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_widget.dart';

class _MockUserProfileBloc extends MockBloc<UserProfileEvent, UserProfileState>
    implements UserProfileBloc {}

void main() {
  late _MockUserProfileBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoadUserProfile());
    registerFallbackValue(UserProfileInitial());
  });

  setUp(() {
    mockBloc = _MockUserProfileBloc();
  });

  Future<void> pump(WidgetTester tester, UserProfileState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<UserProfileState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<UserProfileBloc>.value(
        value: mockBloc,
        child: const ProfileView(),
      ),
    );
    await tester.pump();
  }

  group('ProfileView', () {
    testWidgets('renders initial state', (tester) async {
      await pump(tester, UserProfileInitial());
      expect(find.byType(ProfileView), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await pump(tester, UserProfileLoading());
      expect(find.byType(ProfileView), findsOneWidget);
    });

    testWidgets('renders loaded state with full profile', (tester) async {
      await pump(
        tester,
        UserProfileLoaded(
          name: 'Alice Doe',
          email: 'alice@example.com',
          phone: '+33 6 12 34 56 78',
          memberSince: DateTime(2023, 5, 15),
          travelTypes: const ['beach', 'culture'],
          travelStyle: 'comfort',
          budget: 'medium',
          companions: 'couple',
        ),
      );
      expect(find.byType(ProfileView), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await pump(
        tester,
        UserProfileError(error: const NetworkError('offline')),
      );
      expect(find.byType(ProfileView), findsOneWidget);
    });
  });
}
