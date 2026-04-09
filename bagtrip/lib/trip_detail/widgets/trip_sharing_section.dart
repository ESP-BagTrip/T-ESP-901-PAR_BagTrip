import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripSharingSection extends StatelessWidget {
  final List<TripShare> shares;
  final String tripId;
  final Trip trip;
  final bool isOwner;
  final bool isCompleted;

  const TripSharingSection({
    super.key,
    required this.shares,
    required this.tripId,
    required this.trip,
    required this.isOwner,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.sharingSectionTitle, count: shares.length),
        const SizedBox(height: 12),
        if (shares.isEmpty)
          _EmptyState(
            isOwner: isOwner,
            isCompleted: isCompleted,
            tripId: tripId,
            trip: trip,
          )
        else
          _ParticipantsList(
            shares: shares,
            tripId: tripId,
            trip: trip,
            isOwner: isOwner,
            isCompleted: isCompleted,
          ),
      ],
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.people_rounded, size: 20, color: ColorName.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ColorName.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorName.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Participants List ───────────────────────────────────────────────────────

class _ParticipantsList extends StatelessWidget {
  final List<TripShare> shares;
  final String tripId;
  final Trip trip;
  final bool isOwner;
  final bool isCompleted;

  const _ParticipantsList({
    required this.shares,
    required this.tripId,
    required this.trip,
    required this.isOwner,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = shares.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Owner row — always first
        StaggeredFadeIn(
          index: 0,
          child: _ParticipantTile(
            name: l10n.sharingSectionYou,
            email: null,
            roleBadge: l10n.sharingSectionOwner,
            isOwnerTile: true,
          ),
        ),
        const SizedBox(height: 8),

        // Viewer rows
        ...List.generate(preview.length, (i) {
          final share = preview[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i < preview.length - 1 ? 8 : 0),
            child: StaggeredFadeIn(
              index: i + 1,
              child: _ParticipantTile(
                name: share.userFullName ?? share.userEmail,
                email: share.userFullName != null ? share.userEmail : null,
                roleBadge: share.role == 'EDITOR'
                    ? l10n.shareRoleEditor
                    : l10n.sharingSectionViewer,
                isOwnerTile: false,
                onRemove: isOwner && !isCompleted
                    ? () {
                        final l10n = AppLocalizations.of(context)!;
                        AppHaptics.medium();
                        showAdaptiveAlertDialog(
                          context: context,
                          title: l10n.shareRevokeConfirmTitle,
                          content: l10n.shareRevokeConfirmMessage(
                            share.userFullName ?? share.userEmail,
                          ),
                          confirmLabel: l10n.sharesRevokeButton,
                          cancelLabel: l10n.cancelButton,
                          isDestructive: true,
                          onConfirm: () {
                            context.read<TripDetailBloc>().add(
                              DeleteShareFromDetail(shareId: share.id),
                            );
                          },
                        );
                      }
                    : null,
              ),
            ),
          );
        }),

        if (shares.length > 3) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await SharesRoute(
                tripId: tripId,
                role: trip.role ?? 'OWNER',
              ).push(context);
              if (!context.mounted) return;
              context.read<TripDetailBloc>().add(RefreshTripDetail());
            },
            child: Text(
              l10n.sharingSectionSeeAll(shares.length),
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorName.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Participant Tile ────────────────────────────────────────────────────────

class _ParticipantTile extends StatelessWidget {
  final String name;
  final String? email;
  final String roleBadge;
  final bool isOwnerTile;
  final VoidCallback? onRemove;

  const _ParticipantTile({
    required this.name,
    required this.email,
    required this.roleBadge,
    required this.isOwnerTile,
    this.onRemove,
  });

  String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return text.isNotEmpty ? text[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isOwnerTile
              ? ColorName.primary.withValues(alpha: 0.15)
              : ColorName.primary.withValues(alpha: 0.08),
          child: Text(
            _initials(name),
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ColorName.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (email != null)
                Text(
                  email!,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    color: ColorName.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isOwnerTile
                ? ColorName.primary.withValues(alpha: 0.1)
                : ColorName.textMutedLight.withValues(alpha: 0.15),
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            roleBadge,
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOwnerTile ? ColorName.primary : ColorName.textMutedLight,
            ),
          ),
        ),
        if (onRemove != null) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            color: ColorName.textMutedLight,
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ],
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isOwner;
  final bool isCompleted;
  final String tripId;
  final Trip trip;

  const _EmptyState({
    required this.isOwner,
    required this.isCompleted,
    required this.tripId,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: AppSpacing.allEdgeInsetSpace24,
        child: Column(
          children: [
            // Halo icon
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          ColorName.primary.withValues(alpha: 0.08),
                          ColorName.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorName.primary.withValues(alpha: 0.06),
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      size: 36,
                      color: ColorName.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.sharingSectionEmptyTitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sharingSectionEmptySubtitle,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 13,
                color: ColorName.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),

            if (isOwner && !isCompleted) ...[
              const SizedBox(height: 20),
              _OptionTile(
                icon: Icons.person_add_rounded,
                title: l10n.sharingSectionInvite,
                subtitle: l10n.sharingSectionInviteSubtitle,
                onTap: () async {
                  await SharesRoute(
                    tripId: tripId,
                    role: trip.role ?? 'OWNER',
                  ).push(context);
                  if (!context.mounted) return;
                  context.read<TripDetailBloc>().add(RefreshTripDetail());
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Option Tile ─────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.large16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: AppRadius.large16,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorName.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.medium8,
              ),
              child: Icon(icon, color: ColorName.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
