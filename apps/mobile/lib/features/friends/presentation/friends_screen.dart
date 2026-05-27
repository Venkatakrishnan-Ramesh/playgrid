import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final String me = state.session.userId;

    final List<Friendship> incoming = state.incomingFriendRequests(me);
    final List<Friendship> outgoing = state.outgoingFriendRequests(me);
    final List<String> friendIds = state.friendIdsOf(me);
    final Set<String> outgoingIds =
        outgoing.map((Friendship f) => f.addresseeId).toSet();

    // Members you could still connect with.
    final List<AppUserProfile> suggestions = state.members
        .where((AppUserProfile m) =>
            m.id != me &&
            !friendIds.contains(m.id) &&
            !outgoingIds.contains(m.id) &&
            !incoming.any((Friendship f) => f.requesterId == m.id))
        .toList(growable: false);

    return AppShell(
      title: 'Friends',
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          children: <Widget>[
            if (incoming.isNotEmpty) ...<Widget>[
              _sectionTitle(context, 'Requests (${incoming.length})'),
              ...incoming.map(
                (Friendship f) => Card(
                  child: ListTile(
                    leading: _avatar(state.displayName(f.requesterId)),
                    title: Text(state.displayName(f.requesterId)),
                    subtitle: const Text('Wants to connect'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          onPressed: () =>
                              _respond(context, controller, f.id, accept: true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined),
                          onPressed: () => _respond(context, controller, f.id,
                              accept: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            _sectionTitle(context, 'Your friends (${friendIds.length})'),
            if (friendIds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No friends yet — add some below.'),
              )
            else
              ...friendIds.map(
                (String id) {
                  final Friendship? f = state.friendshipBetween(me, id);
                  return Card(
                    child: ListTile(
                      leading: _avatar(state.displayName(id)),
                      title: Text(state.displayName(id)),
                      subtitle: Text(state.memberById(id)?.department ?? ''),
                      trailing: f == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.person_remove_outlined),
                              tooltip: 'Remove friend',
                              onPressed: () => controller.removeFriend(f.id),
                            ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            _sectionTitle(context, 'Add friends'),
            if (suggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('You are connected with everyone here.'),
              )
            else
              ...suggestions.map(
                (AppUserProfile m) => Card(
                  child: ListTile(
                    leading: _avatar(m.name),
                    title: Text(m.name),
                    subtitle: Text(m.department),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add'),
                      onPressed: () => _add(context, controller, m.id),
                    ),
                  ),
                ),
              ),
            if (outgoing.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              _sectionTitle(context, 'Pending requests you sent'),
              ...outgoing.map(
                (Friendship f) => Card(
                  child: ListTile(
                    leading: _avatar(state.displayName(f.addresseeId)),
                    title: Text(state.displayName(f.addresseeId)),
                    subtitle: const Text('Request sent'),
                    trailing: const Icon(Icons.schedule),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _avatar(String name) => CircleAvatar(
        child: Text(name.isNotEmpty ? name.characters.first : '?'),
      );

  Future<void> _add(
    BuildContext context,
    PlayGridController controller,
    String id,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await controller.sendFriendRequest(id);
      messenger.showSnackBar(const SnackBar(content: Text('Request sent.')));
    } on AppFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _respond(
    BuildContext context,
    PlayGridController controller,
    String friendshipId, {
    required bool accept,
  }) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await controller.respondFriendRequest(friendshipId, accept: accept);
      messenger.showSnackBar(
        SnackBar(content: Text(accept ? 'Friend added.' : 'Request declined.')),
      );
    } on AppFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
