import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/sub_page_hero.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trips/bloc/trip_share_bloc.dart';
import 'package:bagtrip/trips/widgets/share_invite_sheet.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TripSharesView extends StatefulWidget {
  final String tripId;
  final String role;

  const TripSharesView({super.key, required this.tripId, this.role = 'OWNER'});

  @override
  State<TripSharesView> createState() => _TripSharesViewState();
}

class _TripSharesViewState extends State<TripSharesView>
    with TickerProviderStateMixin {
  late final PanelFooterCtaController _footerController;

  @override
  void initState() {
    super.initState();
    _footerController = PanelFooterCtaController(vsync: this);
    _footerController.show();
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  bool get _isOwner => widget.role == 'OWNER';

  void _showInviteSheet(BuildContext context) {
    final bloc = context.read<TripShareBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ShareInviteSheet(tripId: widget.tripId),
      ),
    );
  }

  Future<bool> _showRevokeDialog(BuildContext ctx, TripShare share) async {
    final l10n = AppLocalizations.of(ctx)!;
    bool confirmed = false;
    await showAdaptiveAlertDialog(
      context: ctx,
      title: l10n.shareRevokeConfirmTitle,
      content: l10n.shareRevokeConfirmMessage(
        share.userFullName ?? share.userEmail,
      ),
      confirmLabel: l10n.sharesRevokeButton,
      cancelLabel: l10n.cancelButton,
      isDestructive: true,
      onConfirm: () {
        confirmed = true;
        ctx.read<TripShareBloc>().add(
          DeleteShare(tripId: widget.tripId, shareId: share.id),
        );
      },
    );
    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: ColorName.surfaceVariant,
      body: Column(
        children: [
          SubPageHero(title: l10n.sharesTitle),
          Expanded(
            child: BlocConsumer<TripShareBloc, TripShareState>(
              listener: (context, state) {
                if (state is TripShareError) {
                  final msg = switch (state.error) {
                    NotFoundError() => l10n.shareErrorUserNotFound,
                    ValidationError(:final message)
                        when message.contains('already') =>
                      l10n.shareErrorAlreadyShared,
                    ValidationError(:final message)
                        when message.contains('yourself') =>
                      l10n.shareErrorSelfShare,
                    _ => toUserFriendlyMessage(state.error, l10n),
                  };
                  AppSnackBar.showError(context, message: msg);
                } else if (state is TripShareQuotaExceeded) {
                  AppSnackBar.showError(context, message: l10n.errorQuota);
                } else if (state is TripShareLoaded) {
                  context.read<TripDetailBloc>().add(RefreshTripDetail());
                }
              },
              builder: (context, state) {
                if (state is TripShareLoading) return const LoadingView();
                final shares = state is TripShareLoaded
                    ? state.shares
                    : <TripShare>[];

                if (shares.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.space24),
                    child: ElegantEmptyState(
                      icon: Icons.people_outline,
                      title: l10n.sharesEmpty,
                      subtitle: _isOwner ? l10n.sharesEmptySubtitle : null,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    AppSpacing.space16,
                    AppSpacing.space16,
                    AppSpacing.space32 + 72,
                  ),
                  itemCount: shares.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.space12),
                  itemBuilder: (context, index) {
                    final share = shares[index];
                    final card = _ShareCard(
                      share: share,
                      showRemove: _isOwner,
                      onRemove: _isOwner
                          ? () => _showRevokeDialog(context, share)
                          : null,
                    );
                    if (!_isOwner) return card;
                    return Dismissible(
                      key: ValueKey(share.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        AppHaptics.medium();
                        return _showRevokeDialog(context, share);
                      },
                      background: Container(
                        decoration: const BoxDecoration(
                          color: ColorName.error,
                          borderRadius: AppRadius.large16,
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(
                          right: AppSpacing.space24,
                        ),
                        child: const Icon(
                          Icons.person_remove_rounded,
                          color: Colors.white,
                        ),
                      ),
                      child: card,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isOwner
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space8,
                  AppSpacing.space16,
                  AppSpacing.space16,
                ),
                child: PanelFooterCta(
                  controller: _footerController,
                  child: PillCtaButton(
                    label: l10n.sharesInviteButton,
                    leadingIcon: Icons.person_add_rounded,
                    onTap: () => _showInviteSheet(context),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.share,
    required this.showRemove,
    this.onRemove,
  });

  final TripShare share;
  final bool showRemove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ColorName.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.person_rounded, color: ColorName.primary),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.userFullName ?? share.userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ColorName.primaryDark,
                  ),
                ),
                if (share.userFullName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    share.userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      color: ColorName.hint,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  l10n.tripShareInvitedOnDate(
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(share.invitedAt ?? DateTime.now()),
                  ),
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 11,
                    color: ColorName.hint,
                  ),
                ),
              ],
            ),
          ),
          if (showRemove)
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: ColorName.hint,
              ),
              tooltip: l10n.removeAccessTooltip,
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
