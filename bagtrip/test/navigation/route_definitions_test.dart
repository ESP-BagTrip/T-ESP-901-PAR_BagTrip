import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('Route locations', () {
    test('PlanTripRoute generates /home/plan', () {
      expect(const PlanTripRoute().location, '/home/plan');
    });

    test('TripDetailRoute generates /home/trip/:tripId', () {
      expect(const TripDetailRoute(tripId: 'abc').location, '/home/trip/abc');
    });

    test('DeepLinkTripRoute generates /trip/:tripId', () {
      expect(const DeepLinkTripRoute(tripId: 'xyz').location, '/trip/xyz');
    });

    test('existing TripHomeRoute unchanged', () {
      expect(const TripHomeRoute(tripId: 'x').location, '/home/x');
    });
  });

  group('Redirects', () {
    test('DeepLinkTripRoute.redirect points to /home/:tripId', () {
      final route = const DeepLinkTripRoute(tripId: 'abc-123');
      final redirect = route.redirect(_FakeContext(), _fakeState());
      expect(redirect, '/home/abc-123');
    });

    test('TripDetailRoute.redirect points to /home/:tripId', () {
      final route = const TripDetailRoute(tripId: 'xyz');
      final redirect = route.redirect(_FakeContext(), _fakeState());
      expect(redirect, '/home/xyz');
    });
  });

  group('TripDetailShellRoute', () {
    testWidgets('wraps navigator in BlocProvider<TripDetailBloc> when '
        'tripId is present', (tester) async {
      final navigator = Container(key: const ValueKey('nav'));
      final built = const TripDetailShellRoute().builder(
        _FakeContext(),
        _fakeState(pathParameters: {'tripId': 'trip-42'}),
        navigator,
      );

      expect(built, isA<BlocProvider<TripDetailBloc>>());
      final provider = built as BlocProvider<TripDetailBloc>;
      expect(provider.key, const ValueKey('trip-detail-bloc-trip-42'));
    });

    testWidgets('returns navigator untouched when tripId is absent', (
      tester,
    ) async {
      final navigator = Container(key: const ValueKey('nav'));
      final built = const TripDetailShellRoute().builder(
        _FakeContext(),
        _fakeState(),
        navigator,
      );

      expect(identical(built, navigator), isTrue);
    });
  });
}

GoRouterState _fakeState({Map<String, String> pathParameters = const {}}) {
  return GoRouterState(
    _FakeRouteConfiguration(),
    uri: Uri.parse('/home'),
    matchedLocation: '/home',
    fullPath: '/home',
    pathParameters: pathParameters,
    pageKey: const ValueKey('fake'),
  );
}

class _FakeContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeRouteConfiguration implements RouteConfiguration {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
