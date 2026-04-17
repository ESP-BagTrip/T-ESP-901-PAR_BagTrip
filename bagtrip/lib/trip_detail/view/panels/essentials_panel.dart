import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/pack_item.dart';
import 'package:bagtrip/design/widgets/review/progress_strip.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Essentials (baggage) tab. Groups items by category, shows progress at
/// the top, renders [PackItem] rows. Tap routes to `/baggage` where packed
/// toggling and editing happen (the trip-detail bloc only exposes delete).
class EssentialsPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ElegantEmptyState(
          icon: Icons.luggage_rounded,
          title: l10n.emptyBaggageTitle,
          subtitle: canEdit ? l10n.emptyBaggageSubtitle : null,
        ),
      );
    }

    final groups = _groupByCategory();
    final packed = items.where((i) => i.isPacked).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space24,
      ),
      children: [
        ProgressStrip(
          label: l10n.baggageProgressLabel(packed, items.length).toUpperCase(),
          progress: items.isEmpty ? 0 : packed / items.length,
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
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    primary: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: section.value.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: ColorName.primarySoftLight,
                    ),
                    itemBuilder: (context, idx) {
                      final item = section.value[idx];
                      return _PackRow(
                        item: item,
                        canEdit: canEdit,
                        onTap: canEdit ? () => _openBaggage(context) : () {},
                        onDelete: canEdit
                            ? () {
                                AppHaptics.medium();
                                context.read<TripDetailBloc>().add(
                                  DeleteBaggageItemFromDetail(
                                    baggageItemId: item.id,
                                  ),
                                );
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<BaggageItem>> _groupByCategory() {
    final map = <String, List<BaggageItem>>{};
    for (final item in items) {
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

  void _openBaggage(BuildContext context) {
    BaggageRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
    ).push(context);
  }
}

class _PackRow extends StatelessWidget {
  const _PackRow({
    required this.item,
    required this.canEdit,
    required this.onTap,
    required this.onDelete,
  });

  final BaggageItem item;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PackItem(
      item: item.name,
      reason: item.notes ?? '',
      checked: item.isPacked,
      onTap: onTap,
      onDelete: onDelete,
    );
  }
}
