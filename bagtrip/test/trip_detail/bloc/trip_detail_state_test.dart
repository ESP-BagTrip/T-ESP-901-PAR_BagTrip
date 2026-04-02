import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  TripDetailLoaded makeState({
    String userRole = 'OWNER',
    TripStatus status = TripStatus.planned,
  }) {
    return TripDetailLoaded(
      trip: makeTrip(status: status),
      activities: const [],
      flights: const [],
      accommodations: const [],
      baggageItems: const [],
      shares: const [],
      userRole: userRole,
      completionResult: const CompletionResult(segments: {}, percentage: 0),
    );
  }

  group('TripDetailLoaded role getters', () {
    test('isOwner returns true for OWNER role', () {
      expect(makeState().isOwner, true);
      expect(makeState().isViewer, false);
      expect(makeState().isEditor, false);
    });

    test('isEditor returns true for EDITOR role', () {
      expect(makeState(userRole: 'EDITOR').isEditor, true);
      expect(makeState(userRole: 'EDITOR').isOwner, false);
      expect(makeState(userRole: 'EDITOR').isViewer, false);
    });

    test('isViewer returns true for VIEWER role', () {
      expect(makeState(userRole: 'VIEWER').isViewer, true);
      expect(makeState(userRole: 'VIEWER').isOwner, false);
      expect(makeState(userRole: 'VIEWER').isEditor, false);
    });

    test('canEdit is true for OWNER on non-completed trip', () {
      expect(makeState().canEdit, true);
    });

    test('canEdit is true for EDITOR on non-completed trip', () {
      expect(makeState(userRole: 'EDITOR').canEdit, true);
    });

    test('canEdit is false for VIEWER', () {
      expect(makeState(userRole: 'VIEWER').canEdit, false);
    });

    test('canEdit is false for OWNER on completed trip', () {
      expect(makeState(status: TripStatus.completed).canEdit, false);
    });

    test('canEdit is false for EDITOR on completed trip', () {
      expect(
        makeState(userRole: 'EDITOR', status: TripStatus.completed).canEdit,
        false,
      );
    });
  });
}
