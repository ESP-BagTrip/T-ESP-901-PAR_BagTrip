import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockProfileRepository mockProfileRepo;

  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockProfileRepo = MockProfileRepository();
  });

  group('UserProfileBloc', () {
    // ── LoadUserProfile ────────────────────────────────────────────────

    group('LoadUserProfile', () {
      blocTest<UserProfileBloc, UserProfileState>(
        'emits [UserProfileLoading, UserProfileLoaded] when getCurrentUser and getProfile succeed',
        build: () {
          when(() => mockAuthRepo.getCurrentUser()).thenAnswer(
            (_) async => Success(
              makeUser(phone: '+33612345678', createdAt: DateTime(2024)),
            ),
          );
          when(() => mockProfileRepo.getProfile()).thenAnswer(
            (_) async =>
                Success(makeTravelerProfile(travelTypes: ['beach', 'culture'])),
          );
          return UserProfileBloc(
            authRepository: mockAuthRepo,
            profileRepository: mockProfileRepo,
          );
        },
        act: (bloc) => bloc.add(LoadUserProfile()),
        expect: () => [isA<UserProfileLoading>(), isA<UserProfileLoaded>()],
        verify: (bloc) {
          verify(() => mockAuthRepo.getCurrentUser()).called(1);
          verify(() => mockProfileRepo.getProfile()).called(1);

          final loaded = bloc.state as UserProfileLoaded;
          expect(loaded.name, 'Test User');
          expect(loaded.email, 'test@example.com');
          expect(loaded.phone, '+33612345678');
          expect(loaded.travelTypes, ['beach', 'culture']);
          expect(loaded.travelStyle, 'comfort');
          expect(loaded.budget, 'medium');
          expect(loaded.companions, 'couple');
        },
      );

      blocTest<UserProfileBloc, UserProfileState>(
        'uses email as name when fullName is null',
        build: () {
          when(
            () => mockAuthRepo.getCurrentUser(),
          ).thenAnswer((_) async => Success(makeUser(fullName: null)));
          when(
            () => mockProfileRepo.getProfile(),
          ).thenAnswer((_) async => Success(makeTravelerProfile()));
          return UserProfileBloc(
            authRepository: mockAuthRepo,
            profileRepository: mockProfileRepo,
          );
        },
        act: (bloc) => bloc.add(LoadUserProfile()),
        expect: () => [isA<UserProfileLoading>(), isA<UserProfileLoaded>()],
        verify: (bloc) {
          final loaded = bloc.state as UserProfileLoaded;
          expect(loaded.name, 'test@example.com');
        },
      );

      blocTest<UserProfileBloc, UserProfileState>(
        'uses email as name when fullName is empty/whitespace',
        build: () {
          when(
            () => mockAuthRepo.getCurrentUser(),
          ).thenAnswer((_) async => Success(makeUser(fullName: '   ')));
          when(
            () => mockProfileRepo.getProfile(),
          ).thenAnswer((_) async => Success(makeTravelerProfile()));
          return UserProfileBloc(
            authRepository: mockAuthRepo,
            profileRepository: mockProfileRepo,
          );
        },
        act: (bloc) => bloc.add(LoadUserProfile()),
        expect: () => [isA<UserProfileLoading>(), isA<UserProfileLoaded>()],
        verify: (bloc) {
          final loaded = bloc.state as UserProfileLoaded;
          expect(loaded.name, 'test@example.com');
        },
      );

      blocTest<UserProfileBloc, UserProfileState>(
        'shows dash for phone when phone is null',
        build: () {
          when(
            () => mockAuthRepo.getCurrentUser(),
          ).thenAnswer((_) async => Success(makeUser()));
          when(
            () => mockProfileRepo.getProfile(),
          ).thenAnswer((_) async => Success(makeTravelerProfile()));
          return UserProfileBloc(
            authRepository: mockAuthRepo,
            profileRepository: mockProfileRepo,
          );
        },
        act: (bloc) => bloc.add(LoadUserProfile()),
        expect: () => [isA<UserProfileLoading>(), isA<UserProfileLoaded>()],
        verify: (bloc) {
          final loaded = bloc.state as UserProfileLoaded;
          expect(loaded.phone, '\u2014');
        },
      );

      blocTest<UserProfileBloc, UserProfileState>(
        'emits [UserProfileLoading, UserProfileError] and calls logout when user is null',
        build: () {
          when(
            () => mockAuthRepo.getCurrentUser(),
          ).thenAnswer((_) async => const Success(null));
          when(
            () => mockAuthRepo.logout(),
          ).thenAnswer((_) async => const Success(null));
          return UserProfileBloc(
            authRepository: mockAuthRepo,
            profileRepository: mockProfileRepo,
          );
        },
        act: (bloc) => bloc.add(LoadUserProfile()),
        expect: () => [isA<UserProfileLoading>(), isA<UserProfileError>()],
        verify: (_) {
          verify(() => mockAuthRepo.logout()).called(1);
        },
      );

      blocTest<UserProfileBloc, UserProfileState>(
        'emits [UserProfileLoading, UserProfileError] and calls logout on AuthenticationError',
        build: () {
          when(() => mockAuthRepo.getCurrentUser()).thenAnswer(
            (_) async => const Failure(AuthenticationError('session expired')),
          );
          when(
            () => mockAuthRepo.logout(),
          ).thenAnswer((_) async => const Success(null));
          return UserProfileBloc(
            authRepository: mockAuthRepo,
            profileRepository: mockProfileRepo,
          );
        },
        act: (bloc) => bloc.add(LoadUserProfile()),
        expect: () => [isA<UserProfileLoading>(), isA<UserProfileError>()],
        verify: (_) {
          verify(() => mockAuthRepo.logout()).called(1);
        },
      );

      blocTest<UserProfileBloc, UserProfileState>(
        'emits [UserProfileLoading, UserProfileError] on non-auth failure without calling logout',
        build: () {
          when(() => mockAuthRepo.getCurrentUser()).thenAnswer(
            (_) async => const Failure(NetworkError('no connection')),
          );
          return UserProfileBloc(
            authRepository: mockAuthRepo,
            profileRepository: mockProfileRepo,
          );
        },
        act: (bloc) => bloc.add(LoadUserProfile()),
        expect: () => [isA<UserProfileLoading>(), isA<UserProfileError>()],
        verify: (_) {
          verifyNever(() => mockAuthRepo.logout());
        },
      );

      blocTest<UserProfileBloc, UserProfileState>(
        'still emits UserProfileLoaded with empty profile when getProfile fails',
        build: () {
          when(
            () => mockAuthRepo.getCurrentUser(),
          ).thenAnswer((_) async => Success(makeUser()));
          when(
            () => mockProfileRepo.getProfile(),
          ).thenAnswer((_) async => const Failure(NetworkError('err')));
          return UserProfileBloc(
            authRepository: mockAuthRepo,
            profileRepository: mockProfileRepo,
          );
        },
        act: (bloc) => bloc.add(LoadUserProfile()),
        expect: () => [isA<UserProfileLoading>(), isA<UserProfileLoaded>()],
        verify: (bloc) {
          final loaded = bloc.state as UserProfileLoaded;
          expect(loaded.travelTypes, isEmpty);
          expect(loaded.travelStyle, isNull);
          expect(loaded.budget, isNull);
          expect(loaded.companions, isNull);
        },
      );
    });

    // ── ResetUserProfile ───────────────────────────────────────────────

    group('ResetUserProfile', () {
      blocTest<UserProfileBloc, UserProfileState>(
        'emits [UserProfileInitial] when ResetUserProfile is added',
        build: () => UserProfileBloc(
          authRepository: mockAuthRepo,
          profileRepository: mockProfileRepo,
        ),
        act: (bloc) => bloc.add(ResetUserProfile()),
        expect: () => [isA<UserProfileInitial>()],
      );
    });
  });
}
