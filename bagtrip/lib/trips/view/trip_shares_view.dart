import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/trips/bloc/trip_share_bloc.dart';
import 'package:bagtrip/trips/widgets/share_invite_sheet.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
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

class _TripSharesViewState extends State<TripSharesView> {
  void _showInviteSheet(BuildContext context) {
    final bloc = context.read<TripShareBloc>();
    showModalBottomSheet(
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
    final theme = Theme.of(context);
    final isOwner = widget.role != 'VIEWER';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sharesTitle),
        actions: [
          if (isOwner && AdaptivePlatform.isIOS)
            IconButton(
              icon: const Icon(CupertinoIcons.person_add),
              onPressed: () => _showInviteSheet(context),
            ),
        ],
      ),
      floatingActionButton: isOwner && !AdaptivePlatform.isIOS
          ? FloatingActionButton.extended(
              onPressed: () => _showInviteSheet(context),
              icon: const Icon(Icons.person_add),
              label: Text(l10n.sharesInviteButton),
            )
          : null,
      body: BlocConsumer<TripShareBloc, TripShareState>(
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
          }
          if (state is TripShareQuotaExceeded) {
            AppSnackBar.showError(context, message: l10n.errorQuota);
          }
          if (state is TripShareLoaded) {
            // Success feedback after create/delete is handled by the sheet
          }
        },
        builder: (context, state) {
          final shares = state is TripShareLoaded
              ? state.shares
              : <TripShare>[];
          final isLoading = state is TripShareLoading;

          if (isLoading) return const LoadingView();

          if (shares.isEmpty) {
            return ElegantEmptyState(
              icon: Icons.people_outline,
              title: l10n.sharesEmpty,
              subtitle: l10n.sharesEmptySubtitle,
            );
          }

          return ListView.builder(
            padding: AppSpacing.allEdgeInsetSpace16,
            itemCount: shares.length,
            itemBuilder: (context, index) {
              final share = shares[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: isOwner
                    ? Dismissible(
                        key: ValueKey(share.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          AppHaptics.medium();
                          return _showRevokeDialog(context, share);
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: AppRadius.large16,
                          ),
                          alignment: Alignment.centerRight,
                          padding: AppSpacing.horizontalSpace16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                l10n.sharesRevokeButton,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: FontFamily.b612,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space8),
                              const Icon(
                                Icons.person_remove,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        child: _ShareCard(
                          share: share,
                          showRemove: true,
                          onRemove: () => _showRevokeDialog(context, share),
                        ),
                      )
                    : _ShareCard(share: share, showRemove: false),
              );
            },
          );
        },
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final TripShare share;
  final bool showRemove;
  final VoidCallback? onRemove;

  const _ShareCard({
    required this.share,
    required this.showRemove,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.allEdgeInsetSpace12,
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    share.userFullName ?? share.userEmail,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (share.userFullName != null)
                    Text(
                      share.userEmail,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  Text(
                    'Invit\u00e9 le ${DateFormat('dd/MM/yyyy').format(share.invitedAt ?? DateTime.now())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (showRemove)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
