import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/repositories/notification_repository.dart';
import 'package:bloc/bloc.dart';

/// Holds the account-wide unread-notification count for the tab-bar badge.
///
/// Kept separate from `NotificationBloc` (the history list) so the badge stays
/// live regardless of which screen is open — loading the list never wipes the
/// count and vice-versa.
class NotificationCountCubit extends Cubit<int> {
  final NotificationRepository _repository;

  NotificationCountCubit({NotificationRepository? repository})
    : _repository = repository ?? getIt<NotificationRepository>(),
      super(0);

  /// Re-fetch the unread count from the backend. Best-effort: the repository
  /// already swallows failures and yields 0, so this never throws.
  Future<void> refresh() async {
    final result = await _repository.getUnreadCount();
    if (isClosed) return;
    if (result case Success(:final data)) {
      emit(data);
    }
  }

  /// Sync the badge to a count the notifications list already computed —
  /// avoids a redundant round-trip after a load / mark-as-read.
  void setCount(int count) {
    if (isClosed) return;
    emit(count);
  }

  /// Reset to zero on logout.
  void clear() => emit(0);
}
