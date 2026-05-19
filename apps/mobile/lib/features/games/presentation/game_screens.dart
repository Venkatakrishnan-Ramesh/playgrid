import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;

    return MainShell(
      title: 'Games',
      index: 2,
      fab: FloatingActionButton.extended(
        onPressed: () => context.go('/games/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create game'),
      ),
      body: ListView.separated(
        itemCount: state.games.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final Game game = state.games[index];
          final Sport sport = state.sports
              .firstWhere((Sport value) => value.id == game.sportId);
          final Venue venue = state.venues
              .firstWhere((Venue value) => value.id == game.venueId);
          return FeatureCard(
            title: game.title,
            subtitle:
                '${sport.name} · ${venue.name} · ${formatTimeRange(game.startsAt, game.endsAt)}',
            icon: Icons.emoji_events_outlined,
            trailing: Chip(label: Text(game.status.label)),
            onTap: () => context.go('/games/${game.id}'),
          );
        },
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
    final Game game =
        state.games.firstWhere((Game value) => value.id == gameId);
    final Sport sport =
        state.sports.firstWhere((Sport value) => value.id == game.sportId);
    final Venue venue =
        state.venues.firstWhere((Venue value) => value.id == game.venueId);
    final bool joined = state.gamePlayers.any(
      (GamePlayer value) =>
          value.gameId == game.id && value.userId == state.session.userId,
    );

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
                  '${formatDayMonth(game.startsAt)} · ${game.maxPlayers} max players'),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              if (joined) {
                await controller.leaveGame(game.id);
              } else {
                await controller.joinGame(game.id);
              }
            },
            child: Text(joined ? 'Leave game' : 'Join game'),
          ),
        ],
      ),
    );
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
  final DateTime _startsAt = DateTime.now().add(const Duration(days: 2));
  final DateTime _endsAt =
      DateTime.now().add(const Duration(days: 2, hours: 2));

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _maxPlayers.dispose();
    super.dispose();
  }

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
              TextField(
                  controller: _maxPlayers,
                  decoration: const InputDecoration(labelText: 'Max players')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await controller.createGame(
                    title: _title.text,
                    description: _description.text,
                    sportId: _sportId ?? sports.first.id,
                    venueId: _venueId ?? venues.first.id,
                    startsAt: _startsAt,
                    endsAt: _endsAt,
                    maxPlayers: int.tryParse(_maxPlayers.text) ?? 8,
                  );
                  if (!context.mounted) {
                    return;
                  }
                  context.go('/games');
                },
                child: const Text('Publish game'),
              ),
            ],
          ),
        );
      },
    );
  }
}
