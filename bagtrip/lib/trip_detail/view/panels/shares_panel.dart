import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shares tab (owner-only). Lists invitees with role pill + trash icon.
/// Tap a row routes to the full `/shares` page for invite flow.
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
      itemCount: shares.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space8),
      itemBuilder: (context, index) {
        final share = shares[index];
        return Dismissible(
          key: ValueKey('share-${share.id}'),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          confirmDismiss: (_) async {
            AppHaptics.medium();
            return true;
          },
          onDismissed: (_) {
            context.read<TripDetailBloc>().add(
              DeleteShareFromDetail(shareId: share.id),
            );
          },
          child: _ShareRow(
            share: share,
            onTap: () => SharesRoute(tripId: tripId, role: role).go(context),
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
                child: Text(
                  share.userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorName.primaryDark,
                  ),
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
