import 'package:bagtrip/design/subpage_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveSubpageState', () {
    test('error beats everything', () {
      expect(
        resolveSubpageState(
          isLoading: true,
          hasError: true,
          count: 10,
          canEdit: true,
          isCompleted: false,
        ),
        SubpageScreenState.error,
      );
    });

    test('loading beats role decisions', () {
      expect(
        resolveSubpageState(
          isLoading: true,
          hasError: false,
          count: 0,
          canEdit: false,
          isCompleted: true,
        ),
        SubpageScreenState.booting,
      );
    });

    test('archive (isCompleted) beats viewer and count', () {
      expect(
        resolveSubpageState(
          isLoading: false,
          hasError: false,
          count: 0,
          canEdit: false,
          isCompleted: true,
        ),
        SubpageScreenState.archive,
      );
      expect(
        resolveSubpageState(
          isLoading: false,
          hasError: false,
          count: 25,
          canEdit: true,
          isCompleted: true,
        ),
        SubpageScreenState.archive,
      );
    });

    test('viewer with empty list renders viewer (never blank canvas)', () {
      expect(
        resolveSubpageState(
          isLoading: false,
          hasError: false,
          count: 0,
          canEdit: false,
          isCompleted: false,
        ),
        SubpageScreenState.viewer,
      );
    });

    test('viewer with items renders viewer', () {
      expect(
        resolveSubpageState(
          isLoading: false,
          hasError: false,
          count: 42,
          canEdit: false,
          isCompleted: false,
        ),
        SubpageScreenState.viewer,
      );
    });

    test('editable + zero items → blank canvas', () {
      expect(
        resolveSubpageState(
          isLoading: false,
          hasError: false,
          count: 0,
          canEdit: true,
          isCompleted: false,
        ),
        SubpageScreenState.blankCanvas,
      );
    });

    test('editable + 1 item → sparse', () {
      expect(
        resolveSubpageState(
          isLoading: false,
          hasError: false,
          count: 1,
          canEdit: true,
          isCompleted: false,
        ),
        SubpageScreenState.sparse,
      );
    });

    test('editable + 3 items → sparse (below default threshold)', () {
      expect(
        resolveSubpageState(
          isLoading: false,
          hasError: false,
          count: 3,
          canEdit: true,
          isCompleted: false,
        ),
        SubpageScreenState.sparse,
      );
    });

    test('editable + 4 items → dense (default threshold)', () {
      expect(
        resolveSubpageState(
          isLoading: false,
          hasError: false,
          count: 4,
          canEdit: true,
          isCompleted: false,
        ),
        SubpageScreenState.dense,
      );
    });

    test('custom denseThreshold shifts the crossover', () {
      expect(
        resolveSubpageState(
          isLoading: false,
          hasError: false,
          count: 5,
          canEdit: true,
          isCompleted: false,
          denseThreshold: 10,
        ),
        SubpageScreenState.sparse,
      );
      expect(
        resolveSubpageState(
          isLoading: false,
          hasError: false,
          count: 10,
          canEdit: true,
          isCompleted: false,
          denseThreshold: 10,
        ),
        SubpageScreenState.dense,
      );
    });

    test('loading + editable + zero → booting (not blank canvas)', () {
      expect(
        resolveSubpageState(
          isLoading: true,
          hasError: false,
          count: 0,
          canEdit: true,
          isCompleted: false,
        ),
        SubpageScreenState.booting,
      );
    });

    test('error + completed → error (error precedence)', () {
      expect(
        resolveSubpageState(
          isLoading: false,
          hasError: true,
          count: 0,
          canEdit: true,
          isCompleted: true,
        ),
        SubpageScreenState.error,
      );
    });
  });

  group('densityOf', () {
    test('blankCanvas → blankCanvas', () {
      expect(
        densityOf(SubpageScreenState.blankCanvas),
        HeroDensity.blankCanvas,
      );
    });

    test('sparse → sparse', () {
      expect(densityOf(SubpageScreenState.sparse), HeroDensity.sparse);
    });

    test('dense/viewer/archive → dense', () {
      expect(densityOf(SubpageScreenState.dense), HeroDensity.dense);
      expect(densityOf(SubpageScreenState.viewer), HeroDensity.dense);
      expect(densityOf(SubpageScreenState.archive), HeroDensity.dense);
    });

    test('booting/error → null (handled outside density pipeline)', () {
      expect(densityOf(SubpageScreenState.booting), isNull);
      expect(densityOf(SubpageScreenState.error), isNull);
    });
  });
}
