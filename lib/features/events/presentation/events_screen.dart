import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget buildWithRef(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final List<EventItem> events = controller.state.events;

    return AppShell(
      title: 'Tournaments',
      body: ListView.separated(
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final EventItem event = events[index];
          return Card(
            child: ListTile(
              title: Text(event.title),
              subtitle:
                  Text('${event.location} · ${formatDayMonth(event.startAt)}'),
              trailing: const Icon(Icons.emoji_events_outlined),
            ),
          );
        },
      ),
    );
  }
}
