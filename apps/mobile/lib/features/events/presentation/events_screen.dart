import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final List<EventItem> events = controller.state.events;

    return MainShell(
      title: 'Tournaments',
      index: 4,
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: events.isEmpty
            ? ListView(
                children: const <Widget>[
                  SizedBox(height: 80),
                  Center(child: Text('No tournaments scheduled yet.')),
                ],
              )
            : ListView.separated(
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  final EventItem event = events[index];
                  return Card(
                    child: ListTile(
                      title: Text(event.title),
                      subtitle: Text(
                          '${event.location} · ${formatDayMonth(event.startAt)}'),
                      trailing: const Icon(Icons.emoji_events_outlined),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
