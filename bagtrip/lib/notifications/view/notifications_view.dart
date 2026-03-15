import 'package:bagtrip/components/empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/components/paginated_list.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:bagtrip/notifications/widgets/notification_card.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationsTitle),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(MarkAllRead());
                  },
                  child: Text(
                    AppLocalizations.of(context)!.notificationsMarkAllRead,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const LoadingView();
          }

          if (state is NotificationError) {
            return ErrorView(
              message: toUserFriendlyMessage(
                state.error,
                AppLocalizations.of(context)!,
              ),
              onRetry: () =>
                  context.read<NotificationBloc>().add(LoadNotifications()),
            );
          }

          if (state is NotificationsLoaded) {
            return PaginatedList<AppNotification>(
              items: state.notifications,
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
              onLoadMore: () =>
                  context.read<NotificationBloc>().add(LoadMoreNotifications()),
              onRefresh: () async {
                context.read<NotificationBloc>().add(LoadNotifications());
              },
              padding: const EdgeInsets.symmetric(vertical: 8),
              emptyWidget: EmptyState(
                icon: Icons.notifications_none,
                title: AppLocalizations.of(context)!.notificationsEmpty,
              ),
              groupBy: (notifications) => _groupByDate(context, notifications),
              sectionHeaderBuilder: (context, dateKey) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  dateKey,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              itemBuilder: (context, notif, _) =>
                  NotificationCard(notification: notif),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Map<String, List<AppNotification>> _groupByDate(
    BuildContext context,
    List<AppNotification> notifications,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final Map<String, List<AppNotification>> grouped = {};
    for (final notif in notifications) {
      final dateKey = _formatDateKey(notif.createdAt ?? DateTime.now(), l10n);
      grouped.putIfAbsent(dateKey, () => []).add(notif);
    }
    return grouped;
  }

  String _formatDateKey(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(notifDate).inDays;

    if (diff == 0) return l10n.notificationsToday;
    if (diff == 1) return l10n.notificationsYesterday;
    if (diff < 7) return l10n.notificationsDaysAgo(diff);
    return '${date.day}/${date.month}/${date.year}';
  }
}
