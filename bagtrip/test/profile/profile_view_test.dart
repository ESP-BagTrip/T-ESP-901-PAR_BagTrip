import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/profile/view/profile_view.dart';
import 'package:bagtrip/profile/widgets/profile_delete_account_tile.dart';
import 'package:bagtrip/profile/widgets/profile_section_label.dart';
import 'package:bagtrip/profile/widgets/profile_two_zone_layout.dart';
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

    testWidgets('renders loaded state with section labels and delete tile', (
      tester,
    ) async {
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
      expect(find.byType(ProfileTwoZoneLayout), findsOneWidget);
      expect(find.byType(ProfileSectionLabel), findsNWidgets(2));
      expect(find.byType(ProfileDeleteAccountTile), findsOneWidget);
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
