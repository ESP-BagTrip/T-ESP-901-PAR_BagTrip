import 'package:bagtrip/personalization/bloc/personalization_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/mock_services.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockPersonalizationStorage mockStorage;
  late MockProfileRepository mockProfileRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockStorage = MockPersonalizationStorage();
    mockProfileRepo = MockProfileRepository();
  });

  PersonalizationBloc buildBloc() => PersonalizationBloc(
    authRepository: mockAuthRepo,
    personalizationStorage: mockStorage,
    profileRepository: mockProfileRepo,
  );

  group('PersonalizationBloc', () {
    // ── LoadPersonalization ─────────────────────────────────────────────

    blocTest<PersonalizationBloc, PersonalizationState>(
      'LoadPersonalization with API profile success loads from profile repo and emits PersonalizationLoaded at step 1',
      build: () {
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => Success(makeUser()));
        when(() => mockProfileRepo.getProfile()).thenAnswer(
          (_) async =>
              Success(makeTravelerProfile(travelTypes: ['beach', 'culture'])),
        );
        when(
          () => mockStorage.getTravelFrequency(any()),
        ).thenAnswer((_) async => '');
        when(
          () => mockStorage.getConstraints(any()),
        ).thenAnswer((_) async => '');
        when(
          () => mockStorage.hasSeenPersonalizationWelcome(any()),
        ).thenAnswer((_) async => true);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadPersonalization()),
      expect: () => [
        isA<PersonalizationLoading>(),
        isA<PersonalizationLoaded>()
            .having((s) => s.step, 'step', 1)
            .having((s) => s.selectedTravelTypes, 'selectedTravelTypes', {
              'beach',
              'culture',
            })
            .having((s) => s.travelStyle, 'travelStyle', 'comfort')
            .having((s) => s.budget, 'budget', 'medium')
            .having((s) => s.companions, 'companions', 'couple'),
      ],
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'LoadPersonalization falls back to local storage when getProfile fails',
      build: () {
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => Success(makeUser()));
        when(
          () => mockProfileRepo.getProfile(),
        ).thenAnswer((_) async => const Failure(ServerError('API down')));
        when(
          () => mockStorage.getTravelTypes(any()),
        ).thenAnswer((_) async => 'adventure,nature');
        when(
          () => mockStorage.getTravelStyle(any()),
        ).thenAnswer((_) async => 'backpacker');
        when(() => mockStorage.getBudget(any())).thenAnswer((_) async => 'low');
        when(
          () => mockStorage.getCompanions(any()),
        ).thenAnswer((_) async => 'solo');
        when(
          () => mockStorage.getTravelFrequency(any()),
        ).thenAnswer((_) async => '');
        when(
          () => mockStorage.getConstraints(any()),
        ).thenAnswer((_) async => '');
        when(
          () => mockStorage.hasSeenPersonalizationWelcome(any()),
        ).thenAnswer((_) async => true);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadPersonalization()),
      expect: () => [
        isA<PersonalizationLoading>(),
        isA<PersonalizationLoaded>()
            .having((s) => s.selectedTravelTypes, 'selectedTravelTypes', {
              'adventure',
              'nature',
            })
            .having((s) => s.travelStyle, 'travelStyle', 'backpacker')
            .having((s) => s.budget, 'budget', 'low')
            .having((s) => s.companions, 'companions', 'solo'),
      ],
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'LoadPersonalization with null user emits PersonalizationInitial',
      build: () {
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => const Success(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadPersonalization()),
      expect: () => [
        isA<PersonalizationLoading>(),
        isA<PersonalizationInitial>(),
      ],
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'LoadPersonalization shows welcome (step 0) when no welcome seen and no existing prefs',
      build: () {
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => Success(makeUser()));
        when(
          () => mockProfileRepo.getProfile(),
        ).thenAnswer((_) async => const Failure(ServerError('No profile')));
        when(
          () => mockStorage.getTravelTypes(any()),
        ).thenAnswer((_) async => '');
        when(
          () => mockStorage.getTravelStyle(any()),
        ).thenAnswer((_) async => '');
        when(() => mockStorage.getBudget(any())).thenAnswer((_) async => '');
        when(
          () => mockStorage.getCompanions(any()),
        ).thenAnswer((_) async => '');
        when(
          () => mockStorage.getTravelFrequency(any()),
        ).thenAnswer((_) async => '');
        when(
          () => mockStorage.getConstraints(any()),
        ).thenAnswer((_) async => '');
        when(
          () => mockStorage.hasSeenPersonalizationWelcome(any()),
        ).thenAnswer((_) async => false);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadPersonalization()),
      expect: () => [
        isA<PersonalizationLoading>(),
        isA<PersonalizationLoaded>().having((s) => s.step, 'step', 0),
      ],
    );

    // ── Setters ─────────────────────────────────────────────────────────

    blocTest<PersonalizationBloc, PersonalizationState>(
      'SetTravelTypes updates selectedTravelTypes',
      build: buildBloc,
      seed: () => PersonalizationLoaded(
        step: 1,
        userId: 'user-1',
        selectedTravelTypes: {},
      ),
      act: (bloc) => bloc.add(SetTravelTypes({'beach', 'mountain'})),
      expect: () => [
        isA<PersonalizationLoaded>().having(
          (s) => s.selectedTravelTypes,
          'selectedTravelTypes',
          {'beach', 'mountain'},
        ),
      ],
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'SetTravelStyle updates travelStyle',
      build: buildBloc,
      seed: () => PersonalizationLoaded(
        step: 1,
        userId: 'user-1',
        selectedTravelTypes: {},
      ),
      act: (bloc) => bloc.add(SetTravelStyle('luxury')),
      expect: () => [
        isA<PersonalizationLoaded>().having(
          (s) => s.travelStyle,
          'travelStyle',
          'luxury',
        ),
      ],
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'SetBudget updates budget',
      build: buildBloc,
      seed: () => PersonalizationLoaded(
        step: 1,
        userId: 'user-1',
        selectedTravelTypes: {},
      ),
      act: (bloc) => bloc.add(SetBudget('high')),
      expect: () => [
        isA<PersonalizationLoaded>().having((s) => s.budget, 'budget', 'high'),
      ],
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'SetCompanions updates companions',
      build: buildBloc,
      seed: () => PersonalizationLoaded(
        step: 1,
        userId: 'user-1',
        selectedTravelTypes: {},
      ),
      act: (bloc) => bloc.add(SetCompanions('family')),
      expect: () => [
        isA<PersonalizationLoaded>().having(
          (s) => s.companions,
          'companions',
          'family',
        ),
      ],
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'SetTravelFrequency updates travelFrequency',
      build: buildBloc,
      seed: () => PersonalizationLoaded(
        step: 1,
        userId: 'user-1',
        selectedTravelTypes: {},
      ),
      act: (bloc) => bloc.add(SetTravelFrequency('monthly')),
      expect: () => [
        isA<PersonalizationLoaded>().having(
          (s) => s.travelFrequency,
          'travelFrequency',
          'monthly',
        ),
      ],
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'SetConstraints updates constraints',
      build: buildBloc,
      seed: () => PersonalizationLoaded(
        step: 1,
        userId: 'user-1',
        selectedTravelTypes: {},
      ),
      act: (bloc) => bloc.add(SetConstraints('wheelchair')),
      expect: () => [
        isA<PersonalizationLoaded>().having(
          (s) => s.constraints,
          'constraints',
          'wheelchair',
        ),
      ],
    );

    // ── Navigation ──────────────────────────────────────────────────────

    blocTest<PersonalizationBloc, PersonalizationState>(
      'NextStep increments step',
      build: () {
        when(
          () => mockStorage.setPersonalizationWelcomeSeen(any()),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => PersonalizationLoaded(
        step: 2,
        userId: 'user-1',
        selectedTravelTypes: {},
      ),
      act: (bloc) => bloc.add(PersonalizationNextStep()),
      expect: () => [
        isA<PersonalizationLoaded>().having((s) => s.step, 'step', 3),
      ],
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'PreviousStep decrements step',
      build: buildBloc,
      seed: () => PersonalizationLoaded(
        step: 3,
        userId: 'user-1',
        selectedTravelTypes: {},
      ),
      act: (bloc) => bloc.add(PersonalizationPreviousStep()),
      expect: () => [
        isA<PersonalizationLoaded>().having((s) => s.step, 'step', 2),
      ],
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'Step boundaries: NextStep at max (5) does nothing, PreviousStep at 0 does nothing',
      build: buildBloc,
      seed: () => PersonalizationLoaded(
        step: 5,
        userId: 'user-1',
        selectedTravelTypes: {},
      ),
      act: (bloc) {
        bloc.add(PersonalizationNextStep()); // at max, no-op
        bloc.add(PersonalizationPreviousStep()); // goes from 5 to 4
      },
      expect: () => [
        // Only PreviousStep emits (NextStep at 5 is a no-op)
        isA<PersonalizationLoaded>().having((s) => s.step, 'step', 4),
      ],
    );

    // ── Completion ──────────────────────────────────────────────────────

    blocTest<PersonalizationBloc, PersonalizationState>(
      'SkipPersonalization marks seen and emits PersonalizationSkipped',
      build: () {
        when(
          () => mockStorage.setPersonalizationPromptSeen(any()),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => PersonalizationLoaded(
        step: 2,
        userId: 'user-1',
        selectedTravelTypes: {},
      ),
      act: (bloc) => bloc.add(SkipPersonalization()),
      expect: () => [isA<PersonalizationSkipped>()],
      verify: (_) {
        verify(
          () => mockStorage.setPersonalizationPromptSeen('user-1'),
        ).called(1);
      },
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'SaveAndFinishPersonalization saves all prefs and emits PersonalizationCompleted',
      build: () {
        when(
          () => mockStorage.setTravelTypes(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.setTravelStyle(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.setBudget(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.setCompanions(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.setTravelFrequency(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.setConstraints(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.setPersonalizationPromptSeen(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.setPersonalizationWelcomeSeen(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockProfileRepo.updateProfile(
            travelTypes: any(named: 'travelTypes'),
            travelStyle: any(named: 'travelStyle'),
            budget: any(named: 'budget'),
            companions: any(named: 'companions'),
          ),
        ).thenAnswer((_) async => Success(makeTravelerProfile()));
        return buildBloc();
      },
      seed: () => PersonalizationLoaded(
        step: 5,
        userId: 'user-1',
        selectedTravelTypes: {'beach', 'culture'},
        travelStyle: 'comfort',
        budget: 'medium',
        companions: 'couple',
        travelFrequency: 'monthly',
        constraints: 'none',
      ),
      act: (bloc) => bloc.add(SaveAndFinishPersonalization()),
      expect: () => [isA<PersonalizationCompleted>()],
      verify: (_) {
        verify(() => mockStorage.setTravelTypes('user-1', any())).called(1);
        verify(() => mockStorage.setTravelStyle('user-1', 'comfort')).called(1);
        verify(() => mockStorage.setBudget('user-1', 'medium')).called(1);
        verify(() => mockStorage.setCompanions('user-1', 'couple')).called(1);
        verify(
          () => mockStorage.setTravelFrequency('user-1', 'monthly'),
        ).called(1);
        verify(() => mockStorage.setConstraints('user-1', 'none')).called(1);
        verify(
          () => mockStorage.setPersonalizationPromptSeen('user-1'),
        ).called(1);
        verify(
          () => mockStorage.setPersonalizationWelcomeSeen('user-1'),
        ).called(1);
        verify(
          () => mockProfileRepo.updateProfile(
            travelTypes: any(named: 'travelTypes'),
            travelStyle: 'comfort',
            budget: 'medium',
            companions: 'couple',
          ),
        ).called(1);
      },
    );

    blocTest<PersonalizationBloc, PersonalizationState>(
      'SaveAndFinish with empty userId emits PersonalizationSkipped',
      build: buildBloc,
      seed: () => PersonalizationLoaded(
        step: 5,
        userId: '',
        selectedTravelTypes: {'beach'},
      ),
      act: (bloc) => bloc.add(SaveAndFinishPersonalization()),
      expect: () => [isA<PersonalizationSkipped>()],
    );
  });
}
