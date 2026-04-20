import 'package:bagtrip/baggage/widgets/baggage_add_form.dart';
import 'package:bagtrip/baggage/widgets/baggage_edit_form.dart';
import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/pack_item.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/design/widgets/review/progress_strip.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Essentials (baggage) tab — now a **living** surface.
///
/// Key inversion vs the previous implementation: tapping a row toggles the
/// packed flag in place (via [ToggleBaggagePackedFromDetail]) instead of
/// navigating to `/baggage`. Edit / delete are reachable through the long
/// press context menu (iOS) or swipe-to-delete + trailing icon (Android).
/// A discreet floating `+` opens the add form sheet directly.
class EssentialsPanel extends StatefulWidget {
  const EssentialsPanel({
    super.key,
    required this.tripId,
    required this.items,
    required this.canEdit,
    required this.isCompleted,
    required this.role,
  });

  final String tripId;
  final List<BaggageItem> items;
  final bool canEdit;
  final bool isCompleted;
  final String role;

  @override
  State<EssentialsPanel> createState() => _EssentialsPanelState();
}

class _EssentialsPanelState extends State<EssentialsPanel> {
  int? _lastPackedCount;

  int get _packedCount => widget.items.where((i) => i.isPacked).length;

  @override
  void didUpdateWidget(covariant EssentialsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _packedCount;
    final total = widget.items.length;
    if (_lastPackedCount != null &&
        _lastPackedCount != current &&
        total > 0 &&
        current == total) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppHaptics.success();
        final l10n = AppLocalizations.of(context)!;
        AppSnackBar.showSuccess(context, message: l10n.baggageAllPackedMessage);
      });
    }
    _lastPackedCount = current;
  }

  void _togglePacked(BaggageItem item) {
    AppHaptics.light();
    context.read<TripDetailBloc>().add(
      ToggleBaggagePackedFromDetail(baggageItemId: item.id),
    );
  }

  void _deleteItem(BaggageItem item) {
    AppHaptics.medium();
    context.read<TripDetailBloc>().add(
      DeleteBaggageItemFromDetail(baggageItemId: item.id),
    );
  }

  Future<void> _showAddSheet() async {
    final bloc = context.read<TripDetailBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BaggageAddForm(
        tripId: widget.tripId,
        onSubmit: (data) {
          AppHaptics.medium();
          bloc.add(CreateBaggageItemFromDetail(data: data));
        },
      ),
    );
  }

  Future<void> _showEditSheet(BaggageItem item) async {
    final bloc = context.read<TripDetailBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BaggageEditForm(
        tripId: widget.tripId,
        item: item,
        onSubmit: (data) {
          AppHaptics.medium();
          bloc.add(
            UpdateBaggageItemFromDetail(baggageItemId: item.id, data: data),
          );
        },
      ),
    );
  }

  void _openFullPage() {
    BaggageRoute(
      tripId: widget.tripId,
      role: widget.role,
      isCompleted: widget.isCompleted,
    ).push(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ElegantEmptyState(
          icon: Icons.luggage_rounded,
          title: l10n.emptyBaggageTitle,
          subtitle: widget.canEdit ? l10n.emptyBaggageSubtitle : null,
          ctaLabel: widget.canEdit ? l10n.panelQuickAddItem : null,
          onCta: widget.canEdit ? _showAddSheet : null,
        ),
      );
    }

    final groups = _groupByCategory();
    final packed = _packedCount;
    final total = widget.items.length;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space56 + AppSpacing.space40,
          ),
          children: [
            ProgressStrip(
              label: l10n.baggageProgressLabel(packed, total).toUpperCase(),
              progress: total == 0 ? 0 : packed / total,
            ),
            const SizedBox(height: AppSpacing.space16),
            ...groups.entries.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                      child: Text(
                        section.key.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: ColorName.hint,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.large24,
                        border: Border.all(color: ColorName.primarySoftLight),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.large24,
                        child: Column(
                          children: [
                            for (
                              var idx = 0;
                              idx < section.value.length;
                              idx++
                            ) ...[
                              if (idx > 0)
                                const Divider(
                                  height: 1,
                                  color: ColorName.primarySoftLight,
                                ),
                              _PackRow(
                                item: section.value[idx],
                                canEdit: widget.canEdit,
                                onToggle: () =>
                                    _togglePacked(section.value[idx]),
                                onEdit: () =>
                                    _showEditSheet(section.value[idx]),
                                onDelete: () => _deleteItem(section.value[idx]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _openFullPage,
                child: Text(
                  l10n.panelOpenFullBaggage,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColorName.hint,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.canEdit)
          Positioned(
            bottom: AppSpacing.space24,
            right: AppSpacing.space24,
            child: PanelFab(
              label: l10n.panelQuickAddItem,
              onTap: _showAddSheet,
            ),
          ),
      ],
    );
  }

  Map<String, List<BaggageItem>> _groupByCategory() {
    final map = <String, List<BaggageItem>>{};
    for (final item in widget.items) {
      final key = _categoryFor(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  String _categoryFor(BaggageItem item) {
    final raw = item.category?.trim() ?? '';
    if (raw.isEmpty) return 'Others';
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }
}

class _PackRow extends StatelessWidget {
  const _PackRow({
    required this.item,
    required this.canEdit,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final BaggageItem item;
  final bool canEdit;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final row = PackItem(
      item: item.name,
      reason: item.notes ?? '',
      checked: item.isPacked,
      onTap: canEdit ? onToggle : () {},
    );

    if (!canEdit) return row;

    return Dismissible(
      key: ValueKey('essentials-panel-${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        AppHaptics.medium();
        return true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        color: ColorName.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: AdaptiveContextMenu(
        actions: [
          AdaptiveContextAction(
            label: l10n.panelActionEdit,
            icon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
          AdaptiveContextAction(
            label: l10n.panelActionDelete,
            icon: Icons.delete_outline_rounded,
            onPressed: onDelete,
            isDestructive: true,
          ),
        ],
        child: row,
      ),
    );
  }
}
