import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: () => _onTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
              : null,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor(theme).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(_icon, size: 20, color: _iconColor(theme)),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime(notification.createdAt ?? DateTime.now()),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    switch (notification.type) {
      case 'DEPARTURE_REMINDER':
        return Icons.flight_takeoff;
      case 'FLIGHT_H4':
      case 'FLIGHT_H1':
        return Icons.airplanemode_active;
      case 'MORNING_SUMMARY':
        return Icons.wb_sunny;
      case 'ACTIVITY_H1':
        return Icons.event;
      case 'BUDGET_ALERT':
        return Icons.account_balance_wallet;
      case 'TRIP_ENDED':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _iconColor(ThemeData theme) {
    switch (notification.type) {
      case 'DEPARTURE_REMINDER':
        return Colors.blue;
      case 'FLIGHT_H4':
        return Colors.indigo;
      case 'FLIGHT_H1':
        return Colors.purple;
      case 'MORNING_SUMMARY':
        return Colors.amber;
      case 'ACTIVITY_H1':
        return Colors.green;
      case 'BUDGET_ALERT':
        return Colors.orange;
      case 'TRIP_ENDED':
        return Colors.teal;
      default:
        return theme.colorScheme.primary;
    }
  }

  void _onTap(BuildContext context) {
    // Mark as read
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        MarkNotificationRead(notificationId: notification.id),
      );
    }

    // Deep link based on data
    final data = notification.data;
    if (data == null) return;

    final screen = data['screen'] as String?;
    final tripId = data['tripId'] as String?;

    if (tripId == null) return;

    switch (screen) {
      case 'tripHome':
        context.push('/trips/$tripId');
        break;
      case 'activities':
        context.push('/trips/$tripId/activities');
        break;
      case 'budget':
        context.push('/trips/$tripId/budget');
        break;
      case 'feedback':
        context.push('/trips/$tripId/feedback');
        break;
      default:
        context.push('/trips/$tripId');
    }
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
