import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/timeline_card.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';

/// Overview tab — read-only timeline recap of flights, hotels and
/// activities. Tapping an event switches to the corresponding domain tab via
/// [onJumpToTab].
class OverviewPanel extends StatelessWidget {
  const OverviewPanel({
    super.key,
    required this.state,
    required this.onJumpToTab,
  });

  final TripDetailLoaded state;
  final ValueChanged<int> onJumpToTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final events = _buildEvents(l10n);
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ElegantEmptyState(
          icon: Icons.timeline_rounded,
          title: l10n.emptyActivitiesTitle,
          subtitle: l10n.emptyActivitiesSubtitle,
        ),
      );
    }
    final firstDate = state.trip.startDate ?? DateTime.now();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space24,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final entry = events[index];
        return TimelineCard(
          event: entry.event,
          firstDate: firstDate,
          onTap: () => onJumpToTab(entry.targetTab),
        );
      },
    );
  }

  List<_EntryRecord> _buildEvents(AppLocalizations l10n) {
    final records = <_EntryRecord>[];

    for (final flight in state.flights) {
      final offset = _dayOffset(flight.departureDate);
      records.add(
        _EntryRecord(
          event: TimelineEvent(
            dayOffset: offset,
            type: TimelineEventType.flight,
            title: _flightTitle(flight.departureAirport, flight.arrivalAirport),
            subtitle: [
              if (flight.airline != null && flight.airline!.isNotEmpty)
                flight.airline!,
              flight.flightNumber,
            ].join(' · '),
            badge: l10n.reviewTimelineFlight,
          ),
          targetTab: 1,
        ),
      );
    }

    for (final acc in state.accommodations) {
      final offset = _dayOffset(acc.checkIn);
      records.add(
        _EntryRecord(
          event: TimelineEvent(
            dayOffset: offset,
            type: TimelineEventType.hotel,
            title: acc.name,
            subtitle: acc.address ?? '',
            badge: l10n.reviewTabHotel,
          ),
          targetTab: 2,
        ),
      );
    }

    for (final activity in state.activities) {
      final offset = _dayOffset(activity.date);
      records.add(
        _EntryRecord(
          event: TimelineEvent(
            dayOffset: offset,
            type: TimelineEventType.activity,
            title: activity.title,
            subtitle: activity.location ?? '',
            badge: l10n.reviewTimelineActivity,
          ),
          targetTab: 3,
        ),
      );
    }

    records.sort((a, b) => a.event.dayOffset.compareTo(b.event.dayOffset));
    return records;
  }

  int _dayOffset(DateTime? date) {
    final start = state.trip.startDate;
    if (start == null || date == null) return 0;
    final s = DateTime(start.year, start.month, start.day);
    final d = DateTime(date.year, date.month, date.day);
    return d.difference(s).inDays.clamp(0, 365);
  }

  String _flightTitle(String? from, String? to) {
    final origin = (from?.isNotEmpty ?? false) ? from! : '---';
    final destination = (to?.isNotEmpty ?? false) ? to! : '---';
    return '$origin → $destination';
  }
}

class _EntryRecord {
  _EntryRecord({required this.event, required this.targetTab});

  final TimelineEvent event;
  final int targetTab;
}
