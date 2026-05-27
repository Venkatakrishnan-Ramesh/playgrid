import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/route_paths.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;

    return MainShell(
      title: 'Groups',
      index: 3,
      fab: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.groupCreate),
        icon: const Icon(Icons.add),
        label: const Text('Create group'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: state.groups.isEmpty
            ? ListView(
                children: const <Widget>[
                  SizedBox(height: 80),
                  Center(child: Text('No groups yet. Create one!')),
                ],
              )
            : ListView.separated(
                itemCount: state.groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  final Group group = state.groups[index];
                  final int memberCount = state.membersOf(group.id).length;
                  final bool joined = state.groupMembers.any(
                    (GroupMember member) =>
                        member.groupId == group.id &&
                        member.userId == state.session.userId,
                  );
                  return FeatureCard(
                    title: group.name,
                    subtitle: '${group.description} · $memberCount members',
                    icon: Icons.groups_outlined,
                    trailing: joined
                        ? const Chip(
                            avatar: Icon(Icons.check, size: 16),
                            label: Text('Joined'),
                          )
                        : null,
                    onTap: () => context.push('/groups/${group.id}'),
                  );
                },
              ),
      ),
    );
  }
}

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final Group? group =
        state.groups.where((Group value) => value.id == groupId).firstOrNull;
    if (group == null) {
      return const AppShell(
        title: 'Group',
        body: Center(child: Text('This group is no longer available.')),
      );
    }
    final List<GroupMember> members = state.membersOf(group.id);
    final bool joined = members.any(
      (GroupMember member) => member.userId == state.session.userId,
    );

    return AppShell(
      title: group.name,
      body: ListView(
        children: <Widget>[
          Text(group.description),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              Chip(label: Text(group.isPublic ? 'Public' : 'Private')),
              if (group.department.isNotEmpty)
                Chip(label: Text(group.department)),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: joined
                ? null
                : () async {
                    final ScaffoldMessengerState messenger =
                        ScaffoldMessenger.of(context);
                    await controller.joinGroup(group.id);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Joined ${group.name}.')),
                    );
                  },
            child: Text(joined ? 'Joined' : 'Join group'),
          ),
          const SizedBox(height: 24),
          Text('Members (${members.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (members.isEmpty)
            const Text('No members yet.')
          else
            ...members.map(
              (GroupMember member) {
                final String name = state.displayName(member.userId);
                final bool isYou = member.userId == state.session.userId;
                return Card(
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      child:
                          Text(name.isNotEmpty ? name.characters.first : '?'),
                    ),
                    title: Text(name),
                    subtitle: Text(member.role),
                    trailing: isYou ? const Chip(label: Text('You')) : null,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _department = TextEditingController();
  bool _isPublic = true;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _department.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final PlayGridController controller =
            ref.watch(playGridControllerProvider);

        return AppShell(
          title: 'Create group',
          body: ListView(
            children: <Widget>[
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  hintText: 'e.g. Friday Futsal Crew',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _department,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  hintText: 'e.g. Engineering',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Public group'),
                subtitle: Text(_isPublic
                    ? 'Anyone in the club can find and join.'
                    : 'Only invited members can join.'),
                value: _isPublic,
                onChanged: (bool value) => setState(() => _isPublic = value),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed:
                    _submitting ? null : () => _submit(context, controller),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create group'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(
    BuildContext context,
    PlayGridController controller,
  ) async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name is required.')),
      );
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      await controller.createGroup(
        name: _name.text,
        description: _description.text,
        department: _department.text,
        isPublic: _isPublic,
      );
      if (!context.mounted) {
        return;
      }
      context.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Created "${_name.text.trim()}".')),
      );
    } on AppFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
