import 'dart:async';

import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/components/adaptive/adaptive_indicator.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/subscription/bloc/subscription_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Landing page after Stripe Checkout success.
///
/// Polls the subscription state with exponential backoff (2s → 4s → 8s → 16s,
/// 30s cap) instead of fixed 2s × 5 — Stripe occasionally takes longer than
/// 10 s and the previous behaviour bailed out before the webhook had time
/// to land. The copy shifts from "Finalizing…" to "Almost there…" after the
/// second attempt to make the wait feel honest rather than stuck.
class SubscriptionSuccessPage extends StatefulWidget {
  final String? sessionId;

  const SubscriptionSuccessPage({super.key, this.sessionId});

  @override
  State<SubscriptionSuccessPage> createState() =>
      _SubscriptionSuccessPageState();
}

class _SubscriptionSuccessPageState extends State<SubscriptionSuccessPage> {
  static const _backoffSeconds = [2, 4, 8, 16];
  // Total attempts: 1 immediate + len(_backoffSeconds) retries = 5.
  // Worst case wall time: 30 s.

  Timer? _pollTimer;
  int _attempt = 0;
  _Phase _phase = _Phase.checking;

  @override
  void initState() {
    super.initState();
    // Trigger one user refresh + one subscription refresh on entry, so
    // both blocs reflect the new state if the webhook already landed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(UserRefreshRequested());
      context.read<SubscriptionBloc>().add(LoadSubscription());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextPoll() {
    if (_attempt >= _backoffSeconds.length) {
      setState(() => _phase = _Phase.timedOut);
      return;
    }
    final secs = _backoffSeconds[_attempt];
    _pollTimer = Timer(Duration(seconds: secs), () {
      if (!mounted) return;
      _attempt++;
      // Update copy after the second visible delay so the wait feels
      // intentional rather than stuck.
      if (_attempt == 2 && _phase == _Phase.checking) {
        setState(() => _phase = _Phase.almostThere);
      }
      context.read<AuthBloc>().add(UserRefreshRequested());
      context.read<SubscriptionBloc>().add(LoadSubscription());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => prev != curr,
          listener: (context, state) {
            if (state is! AuthSuccess) return;
            final isPremium = state.authResponse.user.isPremium;
            if (isPremium) {
              if (_phase != _Phase.success) {
                HapticFeedback.lightImpact();
                setState(() => _phase = _Phase.success);
                _pollTimer?.cancel();
              }
            } else if (_phase == _Phase.checking ||
                _phase == _Phase.almostThere) {
              // Still FREE → schedule next backoff tick.
              _pollTimer ??= null;
              if (_pollTimer == null || !_pollTimer!.isActive) {
                _scheduleNextPoll();
              }
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space32,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppAnimationDurations.lengthy,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _buildPhase(context, l10n, state),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhase(
    BuildContext context,
    AppLocalizations l10n,
    AuthState state,
  ) {
    switch (_phase) {
      case _Phase.checking:
      case _Phase.almostThere:
        return _PendingView(
          key: ValueKey('pending-$_phase'),
          label: _phase == _Phase.checking
              ? l10n.subscriptionFinalizing
              : l10n.subscriptionAlmostThere,
        );
      case _Phase.timedOut:
        return _TimeoutView(
          key: const ValueKey('timeout'),
          message: l10n.subscriptionTakingLonger,
          ctaLabel: l10n.subscriptionContinue,
          onContinue: () => const ProfileRoute().go(context),
        );
      case _Phase.success:
        final firstName = (state is AuthSuccess)
            ? _firstName(state.authResponse.user.fullName)
            : null;
        return _WelcomeView(
          key: const ValueKey('welcome'),
          title: firstName != null
              ? '${l10n.subscriptionWelcomePremium}\n$firstName'
              : l10n.subscriptionWelcomePremium,
          ctaLabel: l10n.subscriptionContinue,
          onContinue: () => const ProfileRoute().go(context),
        );
    }
  }

  String? _firstName(String? full) {
    if (full == null) return null;
    final trimmed = full.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.split(' ').first;
  }
}

enum _Phase { checking, almostThere, timedOut, success }

class _PendingView extends StatelessWidget {
  const _PendingView({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AdaptiveIndicator(),
        const SizedBox(height: AppSpacing.space24),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 16,
            color: AppColors.textSecondaryOf(Theme.of(context).brightness),
          ),
        ),
      ],
    );
  }
}

class _TimeoutView extends StatelessWidget {
  const _TimeoutView({
    super.key,
    required this.message,
    required this.ctaLabel,
    required this.onContinue,
  });
  final String message;
  final String ctaLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 17,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.space32),
        CupertinoButton.filled(onPressed: onContinue, child: Text(ctaLabel)),
      ],
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({
    super.key,
    required this.title,
    required this.ctaLabel,
    required this.onContinue,
  });
  final String title;
  final String ctaLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.space48),
        CupertinoButton.filled(onPressed: onContinue, child: Text(ctaLabel)),
      ],
    );
  }
}
