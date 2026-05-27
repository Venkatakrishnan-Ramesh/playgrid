import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/user_picker.dart';
import '../../auth/domain/playgrid_controller.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final String q = _query.trim().toLowerCase();

    bool matches(Game game) {
      if (q.isEmpty) {
        return true;
      }
      final Sport sport = state.sports.byId(game.sportId);
      return game.title.toLowerCase().contains(q) ||
          sport.name.toLowerCase().contains(q);
    }

    bool isJoined(Game game) =>
        state.isPlayerActive(game.id, state.session.userId);

    final List<Game> filtered =
        state.games.where(matches).toList(growable: false);
    final List<Game> joinedGames =
        filtered.where(isJoined).toList(growable: false);
    final List<Game> otherGames =
        filtered.where((Game game) => !isJoined(game)).toList(growable: false);

    return MainShell(
      title: 'Games',
      index: 2,
      fab: FloatingActionButton.extended(
        onPressed: () => context.push('/games/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create game'),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search games or sport',
            ),
            onChanged: (String value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView(
                children: <Widget>[
                  if (filtered.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text('No games found'),
                        subtitle:
                            Text('Try a different search or create a game.'),
                      ),
                    ),
                  if (joinedGames.isNotEmpty) ...<Widget>[
                    const SectionHeader(
                      title: 'Your games',
                      subtitle: 'Games you have joined.',
                    ),
                    const SizedBox(height: 12),
                    ...joinedGames.map(
                      (Game game) => _GameCard(game: game, state: state),
                    ),
                  ],
                  if (otherGames.isNotEmpty) ...<Widget>[
                    if (joinedGames.isNotEmpty) const SizedBox(height: 8),
                    const SectionHeader(
                      title: 'Open to join',
                      subtitle: 'Games you have not joined yet.',
                    ),
                    const SizedBox(height: 12),
                    ...otherGames.map(
                      (Game game) => _GameCard(game: game, state: state),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.state});

  final Game game;
  final PlayGridState state;

  @override
  Widget build(BuildContext context) {
    final Sport sport = state.sports.byId(game.sportId);
    final Venue venue = state.venues.byId(game.venueId);
    final int joinedCount = state.joinedPlayers(game.id).length;
    final bool isFull = joinedCount >= game.maxPlayers;
    final PlayerStatus? myStatus =
        state.playerStatusFor(game.id, state.session.userId);

    final Widget trailing = switch (myStatus) {
      PlayerStatus.joined => const Chip(
          avatar: Icon(Icons.check, size: 16, color: Colors.green),
          label: Text('Joined'),
        ),
      PlayerStatus.waitlisted => const Chip(label: Text('Waitlisted')),
      PlayerStatus.invited => const Chip(
          avatar: Icon(Icons.mail_outline, size: 16),
          label: Text('Invited'),
        ),
      _ => Chip(label: Text(isFull ? 'Full' : game.status.label)),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FeatureCard(
        title: game.title,
        subtitle:
            '${sport.name} · ${venue.name} · $joinedCount/${game.maxPlayers} players',
        icon: Icons.emoji_events_outlined,
        trailing: trailing,
        onTap: () => context.push('/games/${game.id}'),
      ),
    );
  }
}

class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final Game? game =
        state.games.where((Game value) => value.id == gameId).firstOrNull;
    if (game == null) {
      return const AppShell(
        title: 'Game',
        body: Center(child: Text('This game is no longer available.')),
      );
    }
    final Sport sport = state.sports.byId(game.sportId);
    final Venue venue = state.venues.byId(game.venueId);
    final List<GamePlayer> joinedPlayers = state.joinedPlayers(game.id);
    final List<GamePlayer> waitlist = state.waitlistedPlayers(game.id);
    final PlayerStatus? myStatus =
        state.playerStatusFor(game.id, state.session.userId);
    final bool isFull = joinedPlayers.length >= game.maxPlayers;

    return AppShell(
      title: game.title,
      body: ListView(
        children: <Widget>[
          Text(game.description),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Chip(label: Text(sport.name)),
              Chip(label: Text(venue.name)),
              Chip(
                  label: Text(
                      game.waitlistEnabled ? 'Waitlist enabled' : 'Open only')),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: Text(formatTimeRange(game.startsAt, game.endsAt)),
              subtitle: Text(
                  '${formatDayMonth(game.startsAt)} · ${joinedPlayers.length}/${game.maxPlayers} players joined'),
              trailing: isFull
                  ? const Chip(label: Text('Full'))
                  : Chip(
                      label: Text(
                          '${game.maxPlayers - joinedPlayers.length} left')),
            ),
          ),
          const SizedBox(height: 20),
          Text('Players (${joinedPlayers.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (joinedPlayers.isEmpty)
            const Text('No one has joined yet — be the first!')
          else
            ...joinedPlayers.map(
              (GamePlayer player) => _PlayerTile(
                name: state.displayName(player.userId),
                isYou: player.userId == state.session.userId,
              ),
            ),
          if (waitlist.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text('Waitlist (${waitlist.length})',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...waitlist.map(
              (GamePlayer player) => _PlayerTile(
                name: state.displayName(player.userId),
                isYou: player.userId == state.session.userId,
                waitlisted: true,
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (myStatus == PlayerStatus.invited)
            _InviteResponse(game: game, controller: controller)
          else
            _JoinButton(
              game: game,
              myStatus: myStatus,
              isFull: isFull,
              controller: controller,
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _invitePlayers(context, state, controller, game),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Invite players'),
          ),
        ],
      ),
    );
  }

  Future<void> _invitePlayers(
    BuildContext context,
    PlayGridState state,
    PlayGridController controller,
    Game game,
  ) async {
    final Set<String> involved = state.gamePlayers
        .where((GamePlayer p) =>
            p.gameId == game.id &&
            (p.status == PlayerStatus.joined ||
                p.status == PlayerStatus.waitlisted ||
                p.status == PlayerStatus.invited))
        .map((GamePlayer p) => p.userId)
        .toSet();
    final List<PickableUser> candidates = state.members
        .where((AppUserProfile m) =>
            m.id != state.session.userId && !involved.contains(m.id))
        .map((AppUserProfile m) =>
            PickableUser(id: m.id, name: m.name, subtitle: m.department))
        .toList(growable: false);

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final List<String>? selected = await showUserPicker(
      context: context,
      title: 'Invite players',
      confirmLabel: 'Invite',
      candidates: candidates,
    );
    if (selected == null || selected.isEmpty) {
      return;
    }
    await controller.inviteToGame(game.id, selected);
    messenger.showSnackBar(
      SnackBar(content: Text('Invited ${selected.length} player(s).')),
    );
  }
}

class _InviteResponse extends StatelessWidget {
  const _InviteResponse({required this.game, required this.controller});

  final Game game;
  final PlayGridController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('You have been invited to this game.'),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: () => _respond(context, accept: true),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(context, accept: false),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(BuildContext context, {required bool accept}) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await controller.respondGameInvite(game.id, accept: accept);
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(accept ? 'You joined ${game.title}.' : 'Invite declined.'),
        ),
      );
    } on AppFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.name,
    required this.isYou,
    this.waitlisted = false,
  });

  final String name;
  final bool isYou;
  final bool waitlisted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          child: Text(name.isNotEmpty ? name.characters.first : '?'),
        ),
        title: Text(name),
        trailing: isYou
            ? const Chip(label: Text('You'))
            : waitlisted
                ? const Icon(Icons.hourglass_bottom, size: 18)
                : null,
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.game,
    required this.myStatus,
    required this.isFull,
    required this.controller,
  });

  final Game game;
  final PlayerStatus? myStatus;
  final bool isFull;
  final PlayGridController controller;

  @override
  Widget build(BuildContext context) {
    final bool joined = myStatus == PlayerStatus.joined;
    final bool waitlisted = myStatus == PlayerStatus.waitlisted;

    String label;
    if (joined) {
      label = 'Leave game';
    } else if (waitlisted) {
      label = 'Leave waitlist';
    } else if (isFull && !game.waitlistEnabled) {
      label = 'Game full';
    } else if (isFull) {
      label = 'Join waitlist';
    } else {
      label = 'Join game';
    }

    final bool disabled =
        !joined && !waitlisted && isFull && !game.waitlistEnabled;

    return FilledButton(
      onPressed: disabled ? null : () => _onPressed(context),
      child: Text(label),
    );
  }

  Future<void> _onPressed(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool leaving =
        myStatus == PlayerStatus.joined || myStatus == PlayerStatus.waitlisted;
    try {
      if (leaving) {
        await controller.leaveGame(game.id);
        messenger.showSnackBar(
          SnackBar(content: Text('Left ${game.title}.')),
        );
      } else {
        await controller.joinGame(game.id);
        final PlayerStatus? now = controller.state
            .playerStatusFor(game.id, controller.state.session.userId);
        messenger.showSnackBar(
          SnackBar(
            content: Text(now == PlayerStatus.waitlisted
                ? 'Game was full — you are on the waitlist.'
                : 'Joined ${game.title}.'),
          ),
        );
      }
    } on AppFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final TextEditingController _title =
      TextEditingController(text: 'Friday Night Rally');
  final TextEditingController _description =
      TextEditingController(text: 'Open session for mixed skill players.');
  final TextEditingController _maxPlayers = TextEditingController(text: '8');
  String? _sportId;
  String? _venueId;
  DateTime _date = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _maxPlayers.dispose();
    super.dispose();
  }

  DateTime get _startsAt =>
      DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);
  DateTime get _endsAt =>
      DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final PlayGridController controller =
            ref.watch(playGridControllerProvider);
        final List<Sport> sports = controller.state.sports;
        final List<Venue> venues = controller.state.venues;
        _sportId ??= sports.isNotEmpty ? sports.first.id : null;
        _venueId ??= venues.isNotEmpty ? venues.first.id : null;

        return AppShell(
          title: 'Create game',
          body: ListView(
            children: <Widget>[
              TextField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sportId,
                decoration: const InputDecoration(labelText: 'Sport'),
                items: sports
                    .map((Sport sport) => DropdownMenuItem<String>(
                        value: sport.id, child: Text(sport.name)))
                    .toList(),
                onChanged: (String? value) => setState(() => _sportId = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _venueId,
                decoration: const InputDecoration(labelText: 'Venue'),
                items: venues
                    .map((Venue venue) => DropdownMenuItem<String>(
                        value: venue.id, child: Text(venue.name)))
                    .toList(),
                onChanged: (String? value) => setState(() => _venueId = value),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Date'),
                subtitle: Text(formatDayMonth(_startsAt)),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Change'),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Starts'),
                      subtitle: Text(_start.format(context)),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ends'),
                      subtitle: Text(_end.format(context)),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxPlayers,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max players'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting
                    ? null
                    : () => _submit(context, controller, sports, venues),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publish game'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _submit(
    BuildContext context,
    PlayGridController controller,
    List<Sport> sports,
    List<Venue> venues,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (_title.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }
    if (_sportId == null || _venueId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pick a sport and a venue.')),
      );
      return;
    }
    if (!_endsAt.isAfter(_startsAt)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('End time must be after the start time.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await controller.createGame(
        title: _title.text.trim(),
        description: _description.text.trim(),
        sportId: _sportId!,
        venueId: _venueId!,
        startsAt: _startsAt,
        endsAt: _endsAt,
        maxPlayers: int.tryParse(_maxPlayers.text) ?? 8,
      );
      if (!context.mounted) {
        return;
      }
      context.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Published "${_title.text.trim()}".')),
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
