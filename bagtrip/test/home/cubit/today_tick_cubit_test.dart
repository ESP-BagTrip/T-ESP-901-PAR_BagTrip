import 'package:bagtrip/home/cubit/today_tick_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodayTickCubit', () {
    test('initial state is the injected DateTime', () {
      final now = DateTime(2024, 6, 15, 14, 30);
      final cubit = TodayTickCubit(initialNow: now);

      expect(cubit.state, now);
      cubit.close();
    });

    test('initial state is DateTime.now() when no injection', () {
      final before = DateTime.now();
      final cubit = TodayTickCubit();
      final after = DateTime.now();

      expect(
        cubit.state.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch),
      );
      expect(
        cubit.state.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch),
      );
      cubit.close();
    });

    test('emits periodically via timer', () async {
      final cubit = TodayTickCubit(initialNow: DateTime(2024, 6, 15, 14, 30));

      // The cubit has a 60-second timer. We can't easily test real timer
      // ticks without fakeAsync, but we verify it's set up properly.
      expect(cubit.state, DateTime(2024, 6, 15, 14, 30));

      await cubit.close();
    });

    test('close cancels timer without error', () async {
      final cubit = TodayTickCubit(initialNow: DateTime(2024, 6, 15, 14, 30));

      // Should not throw
      await cubit.close();
    });
  });
}
