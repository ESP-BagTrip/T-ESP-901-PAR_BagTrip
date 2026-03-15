import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavigationBloc', () {
    // ── Initial state ──────────────────────────────────────────────────

    test('initial state has activeTab = NavigationTab.home', () {
      final bloc = NavigationBloc();
      expect(bloc.state.activeTab, NavigationTab.home);
      bloc.close();
    });

    // ── NavigationTabChanged ───────────────────────────────────────────

    group('NavigationTabChanged', () {
      blocTest<NavigationBloc, NavigationState>(
        'emits NavigationState(activeTab: activity) when NavigationTabChanged(activity) is added',
        build: () => NavigationBloc(),
        act: (bloc) =>
            bloc.add(const NavigationTabChanged(NavigationTab.activity)),
        expect: () => [
          const NavigationState(activeTab: NavigationTab.activity),
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'emits NavigationState(activeTab: profile) when NavigationTabChanged(profile) is added',
        build: () => NavigationBloc(),
        act: (bloc) =>
            bloc.add(const NavigationTabChanged(NavigationTab.profile)),
        expect: () => [const NavigationState(activeTab: NavigationTab.profile)],
      );

      blocTest<NavigationBloc, NavigationState>(
        'emits NavigationState(activeTab: home) when NavigationTabChanged(home) is added',
        build: () => NavigationBloc(),
        act: (bloc) => bloc.add(const NavigationTabChanged(NavigationTab.home)),
        expect: () => [const NavigationState()],
      );

      blocTest<NavigationBloc, NavigationState>(
        'emits two states when tab is changed twice in sequence',
        build: () => NavigationBloc(),
        act: (bloc) {
          bloc.add(const NavigationTabChanged(NavigationTab.activity));
          bloc.add(const NavigationTabChanged(NavigationTab.profile));
        },
        expect: () => [
          const NavigationState(activeTab: NavigationTab.activity),
          const NavigationState(activeTab: NavigationTab.profile),
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'does not emit when switching to the already active tab (home -> home)',
        build: () => NavigationBloc(),
        act: (bloc) => bloc.add(const NavigationTabChanged(NavigationTab.home)),
        expect: () => [const NavigationState()],
      );
    });
  });
}
