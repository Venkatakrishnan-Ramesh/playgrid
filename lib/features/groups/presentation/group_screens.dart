import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget buildWithRef(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;

    return MainShell(
      title: 'Groups',
      index: 3,
      body: ListView.separated(
        itemCount: state.groups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final Group group = state.groups[index];
          return FeatureCard(
            title: group.name,
            subtitle: group.description,
            icon: Icons.groups_outlined,
            onTap: () => context.go('/groups/${group.id}'),
          );
        },
      ),
    );
  }
}

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget buildWithRef(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final Group group =
        state.groups.firstWhere((Group value) => value.id == groupId);
    final bool joined = state.groupMembers.any(
      (GroupMember member) =>
          member.groupId == group.id && member.userId == state.session.userId,
    );

    return AppShell(
      title: group.name,
      body: ListView(
        children: <Widget>[
          Text(group.description),
          const SizedBox(height: 8),
          Chip(label: Text(group.isPublic ? 'Public' : 'Private')),
          const SizedBox(height: 20),
          FilledButton(
            onPressed:
                joined ? null : () async => controller.joinGroup(group.id),
            child: Text(joined ? 'Joined' : 'Join group'),
          ),
          const SizedBox(height: 20),
          Text('Member list placeholder',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              title: Text('Member directory'),
              subtitle: Text(
                  'This MVP reserves the layout for a real roster in the next iteration.'),
            ),
          ),
        ],
      ),
    );
  }
}
