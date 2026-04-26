import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/invoice.dart';
import 'package:bagtrip/models/subscription_details.dart';
import 'package:bagtrip/subscription/bloc/subscription_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';

SubscriptionDetails _premium({bool cancelAtPeriodEnd = false}) =>
    SubscriptionDetails(
      plan: 'PREMIUM',
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      currentPeriodEnd: DateTime.utc(2026, 5, 30),
    );

SubscriptionDetails _free() => const SubscriptionDetails(plan: 'FREE');

void main() {
  late MockSubscriptionRepository mockRepo;

  setUp(() {
    mockRepo = MockSubscriptionRepository();
  });

  group('SubscriptionBloc', () {
    group('LoadSubscription', () {
      blocTest<SubscriptionBloc, SubscriptionState>(
        'first load: emits loading then loaded with details',
        build: () {
          when(
            () => mockRepo.getDetails(),
          ).thenAnswer((_) async => Success(_premium()));
          return SubscriptionBloc(repository: mockRepo);
        },
        act: (bloc) => bloc.add(LoadSubscription()),
        expect: () => [
          predicate<SubscriptionState>(
            (s) => s.isLoading && !s.hasData,
            'loading without data',
          ),
          predicate<SubscriptionState>(
            (s) => !s.isLoading && s.hasData && s.details!.isPremium,
            'loaded with premium details',
          ),
        ],
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'subsequent load: keeps previous data and uses isRefreshing flag',
        build: () {
          when(
            () => mockRepo.getDetails(),
          ).thenAnswer((_) async => Success(_premium()));
          return SubscriptionBloc(repository: mockRepo);
        },
        seed: () => SubscriptionState(details: _premium()),
        act: (bloc) => bloc.add(LoadSubscription()),
        expect: () => [
          predicate<SubscriptionState>(
            (s) => s.isRefreshing && s.hasData,
            'refreshing with data still visible',
          ),
          predicate<SubscriptionState>(
            (s) => !s.isRefreshing && s.hasData,
            'refreshed',
          ),
        ],
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'failure path: surfaces error without dropping previous data',
        build: () {
          when(
            () => mockRepo.getDetails(),
          ).thenAnswer((_) async => const Failure(NetworkError('offline')));
          return SubscriptionBloc(repository: mockRepo);
        },
        seed: () => SubscriptionState(details: _premium()),
        act: (bloc) => bloc.add(LoadSubscription()),
        expect: () => [
          predicate<SubscriptionState>((s) => s.isRefreshing),
          predicate<SubscriptionState>(
            (s) => !s.isRefreshing && s.error is NetworkError && s.hasData,
            'error surfaced, data retained',
          ),
        ],
      );
    });

    group('Cancel', () {
      blocTest<SubscriptionBloc, SubscriptionState>(
        'success: emits cancelling tag, then idle, and re-fetches details',
        build: () {
          when(
            () => mockRepo.cancel(),
          ).thenAnswer((_) async => const Success(null));
          when(
            () => mockRepo.getDetails(),
          ).thenAnswer((_) async => Success(_premium(cancelAtPeriodEnd: true)));
          return SubscriptionBloc(repository: mockRepo);
        },
        seed: () => SubscriptionState(details: _premium()),
        act: (bloc) => bloc.add(CancelSubscription()),
        expect: () => [
          predicate<SubscriptionState>(
            (s) => s.actionInFlight == SubscriptionAction.cancelling,
          ),
          predicate<SubscriptionState>(
            (s) => s.actionInFlight == SubscriptionAction.idle,
          ),
          predicate<SubscriptionState>((s) => s.isRefreshing),
          predicate<SubscriptionState>(
            (s) => !s.isRefreshing && s.details!.cancelAtPeriodEnd,
            'reload reflects cancel scheduling',
          ),
        ],
        verify: (_) {
          verify(() => mockRepo.cancel()).called(1);
          verify(() => mockRepo.getDetails()).called(1);
        },
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'failure: surfaces error, does not re-fetch',
        build: () {
          when(
            () => mockRepo.cancel(),
          ).thenAnswer((_) async => const Failure(ServerError('boom')));
          return SubscriptionBloc(repository: mockRepo);
        },
        seed: () => SubscriptionState(details: _premium()),
        act: (bloc) => bloc.add(CancelSubscription()),
        expect: () => [
          predicate<SubscriptionState>(
            (s) => s.actionInFlight == SubscriptionAction.cancelling,
          ),
          predicate<SubscriptionState>(
            (s) =>
                s.actionInFlight == SubscriptionAction.idle &&
                s.error is ServerError,
          ),
        ],
        verify: (_) {
          verifyNever(() => mockRepo.getDetails());
        },
      );
    });

    group('Reactivate', () {
      blocTest<SubscriptionBloc, SubscriptionState>(
        'success: tag, idle, re-fetch — clears cancelAtPeriodEnd flag',
        build: () {
          when(
            () => mockRepo.reactivate(),
          ).thenAnswer((_) async => const Success(null));
          when(
            () => mockRepo.getDetails(),
          ).thenAnswer((_) async => Success(_premium()));
          return SubscriptionBloc(repository: mockRepo);
        },
        seed: () =>
            SubscriptionState(details: _premium(cancelAtPeriodEnd: true)),
        act: (bloc) => bloc.add(ReactivateSubscription()),
        expect: () => [
          predicate<SubscriptionState>(
            (s) => s.actionInFlight == SubscriptionAction.reactivating,
          ),
          predicate<SubscriptionState>(
            (s) => s.actionInFlight == SubscriptionAction.idle,
          ),
          predicate<SubscriptionState>((s) => s.isRefreshing),
          predicate<SubscriptionState>(
            (s) => !s.isRefreshing && !s.details!.cancelAtPeriodEnd,
          ),
        ],
      );
    });

    group('Invoices', () {
      blocTest<SubscriptionBloc, SubscriptionState>(
        'load success: populates invoices',
        build: () {
          when(() => mockRepo.listInvoices()).thenAnswer(
            (_) async => const Success([Invoice(id: 'in_1', status: 'paid')]),
          );
          return SubscriptionBloc(repository: mockRepo);
        },
        act: (bloc) => bloc.add(LoadInvoices()),
        expect: () => [
          predicate<SubscriptionState>((s) => s.invoicesLoading),
          predicate<SubscriptionState>(
            (s) => !s.invoicesLoading && s.invoices.length == 1,
          ),
        ],
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'load failure: invoicesError set, main details untouched',
        build: () {
          when(
            () => mockRepo.listInvoices(),
          ).thenAnswer((_) async => const Failure(NetworkError('offline')));
          return SubscriptionBloc(repository: mockRepo);
        },
        seed: () => SubscriptionState(details: _premium()),
        act: (bloc) => bloc.add(LoadInvoices()),
        expect: () => [
          predicate<SubscriptionState>((s) => s.invoicesLoading),
          predicate<SubscriptionState>(
            (s) =>
                !s.invoicesLoading &&
                s.invoicesError is NetworkError &&
                s.hasData,
            'invoices error set, subscription details preserved',
          ),
        ],
      );
    });

    group('Reset', () {
      blocTest<SubscriptionBloc, SubscriptionState>(
        'on logout: clears state',
        build: () => SubscriptionBloc(repository: mockRepo),
        seed: () => SubscriptionState(details: _free()),
        act: (bloc) => bloc.add(ResetSubscription()),
        expect: () => [
          predicate<SubscriptionState>((s) => !s.hasData && s.invoices.isEmpty),
        ],
      );
    });
  });
}
