import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/sheets/quick_preview_sheet.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trips/widgets/share_invite_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Shares tab (owner-only). The panel owns the full invite / revoke
/// lifecycle — there is no dedicated `/shares` sub-page anymore (it was
/// a pure mirror).
class SharesPanel extends StatelessWidget {
  const SharesPanel({
    super.key,
    required this.tripId,
    required this.shares,
    required this.role,
  });

  final String tripId;
  final List<TripShare> shares;
  final String role;

  Future<void> _showInviteSheet(BuildContext context) async {
    final bloc = context.read<TripDetailBloc>();
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareInviteSheet(
        tripId: tripId,
        onSubmit: ({required email, required role, message}) {
          AppHaptics.medium();
          bloc.add(
            CreateShareFromDetail(email: email, role: role, message: message),
          );
          AppSnackBar.showSuccess(context, message: l10n.shareInviteSuccess);
        },
      ),
    );
  }

  void _delete(BuildContext context, TripShare share) {
    AppHaptics.medium();
    context.read<TripDetailBloc>().add(
      DeleteShareFromDetail(shareId: share.id),
    );
  }

  Future<void> _showPreview(BuildContext context, TripShare share) async {
    final l10n = AppLocalizations.of(context)!;
    AppHaptics.light();
    await showQuickPreviewSheet(
      context: context,
      icon: Icons.person_rounded,
      title: share.userFullName ?? share.userEmail,
      subtitle: share.role,
      body: _SharePreviewBody(share: share),
      primaryAction: QuickPreviewAction(
        label: l10n.shareCopyLink,
        icon: Icons.link_rounded,
        onPressed: () {
          Navigator.of(context).pop();
          AppSnackBar.showSuccess(context, message: l10n.shareInviteLinkCopied);
        },
      ),
      destructiveAction: QuickPreviewAction(
        label: l10n.shareRevokeAccess,
        icon: Icons.person_remove_rounded,
        onPressed: () {
          Navigator.of(context).pop();
          _delete(context, share);
        },
        isDestructive: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (shares.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ElegantEmptyState(
          icon: Icons.people_alt_rounded,
          title: l10n.emptySharesTitle,
          subtitle: l10n.emptySharesSubtitle,
          ctaLabel: l10n.panelInviteCollaborator,
          onCta: () => _showInviteSheet(context),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space24,
      ),
      itemCount: shares.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space8),
            child: OutlinedButton.icon(
              onPressed: () => _showInviteSheet(context),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: Text(l10n.panelInviteCollaborator),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: ColorName.primaryDark,
                side: const BorderSide(color: ColorName.primarySoftLight),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.large16,
                ),
              ),
            ),
          );
        }
        final share = shares[index - 1];
        return Dismissible(
          key: ValueKey('share-${share.id}'),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          confirmDismiss: (_) async {
            AppHaptics.medium();
            return true;
          },
          onDismissed: (_) => _delete(context, share),
          child: AdaptiveContextMenu(
            actions: [
              AdaptiveContextAction(
                label: l10n.shareRevokeAccess,
                icon: Icons.person_remove_rounded,
                onPressed: () => _delete(context, share),
                isDestructive: true,
              ),
            ],
            child: _ShareRow(
              share: share,
              onTap: () => _showPreview(context, share),
            ),
          ),
        );
      },
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.share, required this.onTap});

  final TripShare share;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppRadius.large16,
      child: InkWell(
        borderRadius: AppRadius.large16,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: ColorName.primary.withValues(alpha: 0.15),
                child: Text(
                  _initials(share.userEmail),
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ColorName.primaryDark,
                  ),
                ),
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
                        fontFamily: FontFamily.dMSans,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ColorName.primaryDark,
                      ),
                    ),
                    if (share.userFullName != null)
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
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                  vertical: AppSpacing.space4,
                ),
                decoration: BoxDecoration(
                  color: ColorName.secondary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  share.role.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: ColorName.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String email) {
    if (email.isEmpty) return '?';
    final parts = email.split('@').first.split(RegExp(r'[._-]'));
    return parts
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
  }
}

class _SharePreviewBody extends StatelessWidget {
  const _SharePreviewBody({required this.share});

  final TripShare share;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invitedAt = share.invitedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          share.userEmail,
          style: const TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 14,
            color: ColorName.primaryDark,
          ),
        ),
        const SizedBox(height: AppSpacing.space16),
        if (invitedAt != null)
          Text(
            l10n.tripShareInvitedOnDate(
              DateFormat('dd/MM/yyyy').format(invitedAt),
            ),
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 12,
              color: ColorName.hint,
            ),
          ),
      ],
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      decoration: const BoxDecoration(
        color: ColorName.error,
        borderRadius: AppRadius.large16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
