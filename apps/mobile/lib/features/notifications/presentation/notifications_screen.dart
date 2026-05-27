import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final List<NotificationItem> notifications = state.notifications
        .where((NotificationItem item) => item.userId == state.session.userId)
        .toList(growable: false);
    final int unread = state.unreadNotificationCount(state.session.userId);

    return AppShell(
      title: 'Notifications',
      actions: <Widget>[
        if (unread > 0)
          TextButton(
            onPressed: controller.markAllNotificationsRead,
            child: const Text('Mark all read'),
          ),
      ],
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: notifications.isEmpty
            ? ListView(
                children: const <Widget>[
                  SizedBox(height: 80),
                  Center(child: Text('You are all caught up.')),
                ],
              )
            : ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  final NotificationItem item = notifications[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(item.isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active),
                      title: Text(item.title),
                      subtitle: Text(
                          '${item.body}\n${formatDayMonth(item.createdAt)}'),
                      isThreeLine: true,
                      trailing: item.isRead
                          ? null
                          : TextButton(
                              onPressed: () =>
                                  controller.markNotificationRead(item.id),
                              child: const Text('Mark read'),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
