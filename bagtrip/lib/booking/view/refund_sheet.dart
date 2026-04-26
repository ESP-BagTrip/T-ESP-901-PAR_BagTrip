import 'package:bagtrip/booking/bloc/booking_bloc.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/repositories/booking_repository.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Refund request bottom sheet.
///
/// Mode picker (full / partial) toggles a numeric field. Reason picker
/// surfaces the three Stripe-allowed values, defaulting to "Requested by
/// customer" — the overwhelmingly common case. The sheet validates the
/// amount client-side against the captured total to short-circuit the
/// most common error before the network call.
class RefundSheet extends StatefulWidget {
  const RefundSheet({
    super.key,
    required this.intentId,
    required this.capturedAmountCents,
    required this.currency,
    this.tripSummary,
  });

  final String intentId;

  /// Authoritative captured amount in cents. The bloc still validates
  /// against Stripe server-side; this is just for the UI cap.
  final int capturedAmountCents;

  final String currency;

  /// Human-readable line ("Paris → New York"). Optional — context only.
  final String? tripSummary;

  static Future<void> show(
    BuildContext context, {
    required String intentId,
    required int capturedAmountCents,
    required String currency,
    String? tripSummary,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<BookingBloc>(),
        child: RefundSheet(
          intentId: intentId,
          capturedAmountCents: capturedAmountCents,
          currency: currency,
          tripSummary: tripSummary,
        ),
      ),
    );
  }

  @override
  State<RefundSheet> createState() => _RefundSheetState();
}

enum _RefundMode { full, partial }

class _RefundSheetState extends State<RefundSheet> {
  _RefundMode _mode = _RefundMode.full;
  RefundReason _reason = RefundReason.requestedByCustomer;
  final _amountController = TextEditingController();
  String? _amountError;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? _parseAmountCents() {
    final text = _amountController.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return null;
    return (parsed * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final formatter = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: _currencySymbol(widget.currency),
      decimalDigits: 2,
    );
    final capturedDisplay = formatter.format(widget.capturedAmountCents / 100);

    return BlocConsumer<BookingBloc, BookingState>(
      listenWhen: (prev, curr) =>
          (prev is RefundInProgress && curr is RefundSucceeded) ||
          (prev is RefundInProgress && curr is PaymentFailed),
      listener: (context, state) {
        if (state is RefundSucceeded) {
          Navigator.of(context).pop();
          HapticFeedback.lightImpact();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppSnackBar.showSuccess(
              context,
              message: l10n.refundSuccessMessage,
            );
          });
        } else if (state is PaymentFailed) {
          AppSnackBar.showError(
            context,
            message: toUserFriendlyMessage(state.error, l10n),
          );
        }
      },
      builder: (context, state) {
        final loading = state is RefundInProgress;
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.cornerRadius28),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.space24,
              AppSpacing.space12,
              AppSpacing.space24,
              mediaQuery.viewInsets.bottom + AppSpacing.space24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textDisabled.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                Text(
                  l10n.refundSheetTitle,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (widget.tripSummary != null) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    widget.tripSummary!,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      color: AppColors.textSecondaryOf(theme.brightness),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space4),
                Text(
                  l10n.refundSheetCapturedLabel(capturedDisplay),
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    color: AppColors.textDisabled,
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                CupertinoSlidingSegmentedControl<_RefundMode>(
                  groupValue: _mode,
                  onValueChanged: (mode) {
                    if (loading || mode == null) return;
                    HapticFeedback.selectionClick();
                    setState(() {
                      _mode = mode;
                      _amountError = null;
                    });
                  },
                  children: {
                    _RefundMode.full: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(l10n.refundModeFull),
                    ),
                    _RefundMode.partial: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(l10n.refundModePartial),
                    ),
                  },
                ),
                if (_mode == _RefundMode.partial) ...[
                  const SizedBox(height: AppSpacing.space16),
                  CupertinoTextField(
                    controller: _amountController,
                    enabled: !loading,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    placeholder: l10n.refundAmountHint(capturedDisplay),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: AppSpacing.space12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.inputBackgroundDark
                          : AppColors.surfaceVariant,
                      borderRadius: AppRadius.medium8,
                    ),
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      color: theme.colorScheme.onSurface,
                    ),
                    onChanged: (_) => setState(() => _amountError = null),
                  ),
                  if (_amountError != null) ...[
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      _amountError!,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.space24),
                Text(
                  l10n.refundReasonLabel,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(theme.brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                _ReasonPicker(
                  value: _reason,
                  enabled: !loading,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _reason = value);
                  },
                ),
                const SizedBox(height: AppSpacing.space32),
                CupertinoButton.filled(
                  onPressed: loading ? null : _onSubmit,
                  child: loading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : Text(l10n.refundConfirm),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSubmit() {
    final l10n = AppLocalizations.of(context)!;
    if (_mode == _RefundMode.partial) {
      final cents = _parseAmountCents();
      if (cents == null || cents <= 0) {
        setState(() => _amountError = l10n.errorValidation);
        return;
      }
      if (cents > widget.capturedAmountCents) {
        setState(() => _amountError = l10n.errorRefundExceedsRemaining);
        return;
      }
    }
    HapticFeedback.mediumImpact();
    final amount = _mode == _RefundMode.partial ? _parseAmountCents() : null;
    context.read<BookingBloc>().add(
      RefundPayment(intentId: widget.intentId, amount: amount, reason: _reason),
    );
  }

  String _currencySymbol(String? currency) {
    return switch (currency?.toLowerCase()) {
      'eur' => '€',
      'usd' => r'$',
      'gbp' => '£',
      _ => currency?.toUpperCase() ?? '',
    };
  }
}

class _ReasonPicker extends StatelessWidget {
  const _ReasonPicker({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final RefundReason value;
  final ValueChanged<RefundReason> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entries = <(RefundReason, String)>[
      (RefundReason.requestedByCustomer, l10n.refundReasonRequestedByCustomer),
      (RefundReason.duplicate, l10n.refundReasonDuplicate),
      (RefundReason.fraudulent, l10n.refundReasonFraudulent),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.inputBackgroundDark
            : AppColors.surfaceVariant,
        borderRadius: AppRadius.medium8,
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            InkWell(
              onTap: enabled ? () => onChanged(entries[i].$1) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entries[i].$2,
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (entries[i].$1 == value)
                      const Icon(
                        Icons.check_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
            if (i < entries.length - 1)
              Container(
                height: 1,
                color: AppColors.border.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }
}
