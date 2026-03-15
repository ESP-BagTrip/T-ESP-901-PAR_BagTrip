import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavigationBloc', () {
    // ── Initial state ──────────────────────────────────────────────────

    test('initial state has activeTab = NavigationTab.trips', () {
      final bloc = NavigationBloc();
      expect(bloc.state.activeTab, NavigationTab.trips);
      bloc.close();
    });

    // ── NavigationTabChanged ───────────────────────────────────────────

    group('NavigationTabChanged', () {
      blocTest<NavigationBloc, NavigationState>(
        'emits NavigationState(activeTab: explorer) when NavigationTabChanged(explorer) is added',
        build: () => NavigationBloc(),
        act: (bloc) =>
            bloc.add(const NavigationTabChanged(NavigationTab.explorer)),
        expect: () => [
          const NavigationState(activeTab: NavigationTab.explorer),
        ],
      );

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
        'emits NavigationState(activeTab: trips) when NavigationTabChanged(trips) is added',
        build: () => NavigationBloc(),
        act: (bloc) =>
            bloc.add(const NavigationTabChanged(NavigationTab.trips)),
        expect: () => [const NavigationState()],
      );

      blocTest<NavigationBloc, NavigationState>(
        'emits two states when tab is changed twice in sequence',
        build: () => NavigationBloc(),
        act: (bloc) {
          bloc.add(const NavigationTabChanged(NavigationTab.explorer));
          bloc.add(const NavigationTabChanged(NavigationTab.profile));
        },
        expect: () => [
          const NavigationState(activeTab: NavigationTab.explorer),
          const NavigationState(activeTab: NavigationTab.profile),
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'does not emit when switching to the already active tab (trips -> trips)',
        build: () => NavigationBloc(),
        act: (bloc) =>
            bloc.add(const NavigationTabChanged(NavigationTab.trips)),
        expect: () => [const NavigationState()],
      );
    });
  });
}
