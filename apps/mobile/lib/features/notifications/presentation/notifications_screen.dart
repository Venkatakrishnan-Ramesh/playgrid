import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final List<NotificationItem> notifications = controller.state.notifications;

    return MainShell(
      title: 'Notifications',
      index: 4,
      body: ListView.separated(
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
              subtitle: Text('${item.body}\n${formatDayMonth(item.createdAt)}'),
              isThreeLine: true,
              trailing: item.isRead
                  ? null
                  : TextButton(
                      onPressed: () => controller.markNotificationRead(item.id),
                      child: const Text('Mark read'),
                    ),
            ),
          );
        },
      ),
    );
  }
}
