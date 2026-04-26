import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/invoice.dart';
import 'package:bagtrip/models/subscription_details.dart';
import 'package:bagtrip/repositories/subscription_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

/// App-level Bloc that owns the user's subscription state.
///
/// Lives at the [MultiBlocProvider] level (next to [AuthBloc] / [HomeBloc])
/// so paywalls, the manage-subscription screen and feature gates all read
/// from a single source of truth instead of polling endpoints individually.
///
/// Cancel / reactivate calls fire a follow-up [LoadSubscription] so the UI
/// refreshes from Stripe — webhooks update `User.plan`, but the local
/// [SubscriptionDetails] needs to be re-fetched explicitly.
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc({SubscriptionRepository? repository, AuthBloc? authBloc})
    : _repository = repository ?? getIt<SubscriptionRepository>(),
      _authBloc = authBloc,
      super(const SubscriptionState.initial()) {
    on<LoadSubscription>(_onLoad);
    on<RefreshSubscription>(_onRefresh);
    on<LoadInvoices>(_onLoadInvoices);
    on<CancelSubscription>(_onCancel);
    on<ReactivateSubscription>(_onReactivate);
    on<ResetSubscription>(_onReset);
  }

  final SubscriptionRepository _repository;
  // Optional: when wired, cancel/reactivate also kick a User refresh so
  // gating UI (paywalls, premium badges) react in real time.
  final AuthBloc? _authBloc;

  Future<void> _onLoad(
    LoadSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    if (state.details == null) {
      emit(state.copyWith(isLoading: true, error: null));
    } else {
      // Subsequent loads keep the previous snapshot visible to avoid the
      // page going blank between fetches — feels more honest than a flicker.
      emit(state.copyWith(isRefreshing: true, error: null));
    }
    final result = await _repository.getDetails();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            details: data,
            isLoading: false,
            isRefreshing: false,
            error: null,
          ),
        );
      case Failure(:final error):
        emit(
          state.copyWith(isLoading: false, isRefreshing: false, error: error),
        );
    }
  }

  Future<void> _onRefresh(
    RefreshSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    add(LoadSubscription());
  }

  Future<void> _onLoadInvoices(
    LoadInvoices event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(invoicesLoading: true, invoicesError: null));
    final result = await _repository.listInvoices(limit: event.limit);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            invoices: data,
            invoicesLoading: false,
            invoicesError: null,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(invoicesLoading: false, invoicesError: error));
    }
  }

  Future<void> _onCancel(
    CancelSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(actionInFlight: SubscriptionAction.cancelling));
    final result = await _repository.cancel();
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(state.copyWith(actionInFlight: SubscriptionAction.idle));
        // Re-fetch from Stripe so cancelAtPeriodEnd flips locally.
        add(LoadSubscription());
        _authBloc?.add(UserRefreshRequested());
      case Failure(:final error):
        emit(
          state.copyWith(actionInFlight: SubscriptionAction.idle, error: error),
        );
    }
  }

  Future<void> _onReactivate(
    ReactivateSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(actionInFlight: SubscriptionAction.reactivating));
    final result = await _repository.reactivate();
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(state.copyWith(actionInFlight: SubscriptionAction.idle));
        add(LoadSubscription());
        _authBloc?.add(UserRefreshRequested());
      case Failure(:final error):
        emit(
          state.copyWith(actionInFlight: SubscriptionAction.idle, error: error),
        );
    }
  }

  void _onReset(ResetSubscription event, Emitter<SubscriptionState> emit) {
    emit(const SubscriptionState.initial());
  }
}
