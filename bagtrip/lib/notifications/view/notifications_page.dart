import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:bagtrip/notifications/cubit/notification_count_cubit.dart';
import 'package:bagtrip/notifications/view/notifications_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger initial load.
    context.read<NotificationBloc>().add(LoadNotifications());
    // Keep the tab-bar badge in sync with the list — a load and a
    // mark-as-read both re-emit NotificationsLoaded with a fresh count.
    return BlocListener<NotificationBloc, NotificationState>(
      listenWhen: (_, current) => current is NotificationsLoaded,
      listener: (context, state) {
        if (state is NotificationsLoaded) {
          context.read<NotificationCountCubit>().setCount(state.unreadCount);
        }
      },
      child: const NotificationsView(),
    );
  }
}
