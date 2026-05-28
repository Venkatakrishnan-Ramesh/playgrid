import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/domain/playgrid_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final List<Booking> upcoming =
        state.upcomingBookingsFor(state.session.userId);
    final List<Game> openGames = state.openGames();
    final int unread = state.unreadNotificationCount(state.session.userId);
    final int friendRequests =
        state.pendingFriendRequestCount(state.session.userId);

    return MainShell(
      title: 'PlayGrid Club',
      index: 0,
      actions: <Widget>[
        IconButton(
          onPressed: () => context.push(RoutePaths.friends),
          icon: friendRequests > 0
              ? Badge.count(
                  count: friendRequests,
                  child: const Icon(Icons.people_outline),
                )
              : const Icon(Icons.people_outline),
        ),
        IconButton(
          onPressed: () => context.push(RoutePaths.notifications),
          icon: unread > 0
              ? Badge.count(
                  count: unread,
                  child: const Icon(Icons.notifications_outlined),
                )
              : const Icon(Icons.notifications_outlined),
        ),
        IconButton(
          onPressed: () => context.push(RoutePaths.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          children: <Widget>[
            Text(
              'Your sports coordination hub',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _HomeActionCard(
                  title: 'Tennis bookings',
                  subtitle: 'Request a tennis slot',
                  icon: Icons.sports_tennis_outlined,
                  onTap: () => context.push(RoutePaths.tennis),
                ),
                if (state.session.isAdmin ||
                    (state.profile?.isAdmin ?? false))
                  _HomeActionCard(
                    title: 'Admin dashboard',
                    subtitle: 'Review requests & slots',
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: () => context.push(RoutePaths.admin),
                  ),
                _HomeActionCard(
                  title: 'Book a Slot',
                  subtitle: 'Reserve courts and turf',
                  icon: Icons.calendar_month_outlined,
                  onTap: () => context.push(RoutePaths.venues),
                ),
                _HomeActionCard(
                  title: 'Join a Game',
                  subtitle: 'Open games and waitlists',
                  icon: Icons.emoji_events_outlined,
                  onTap: () => context.push(RoutePaths.games),
                ),
                _HomeActionCard(
                  title: 'My Bookings',
                  subtitle: 'Upcoming bookings',
                  icon: Icons.event_available_outlined,
                  onTap: () => context.push(RoutePaths.bookings),
                ),
                _HomeActionCard(
                  title: 'Groups',
                  subtitle: 'Department clubs',
                  icon: Icons.groups_outlined,
                  onTap: () => context.push(RoutePaths.groups),
                ),
                _HomeActionCard(
                  title: 'Tournaments',
                  subtitle: 'Club events',
                  icon: Icons.local_fire_department_outlined,
                  onTap: () => context.push(RoutePaths.events),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Upcoming booking',
              subtitle: 'Your nearest confirmed or pending slot.',
              action: TextButton(
                onPressed: () => context.push(RoutePaths.bookings),
                child: const Text('View all'),
              ),
            ),
            const SizedBox(height: 12),
            if (upcoming.isEmpty)
              const _EmptyPreview(title: 'No upcoming bookings yet')
            else
              ...upcoming.take(1).map(
                    (Booking booking) => _BookingPreview(
                      booking: booking,
                      venue: state.venues.firstWhere(
                          (Venue venue) => venue.id == booking.venueId),
                      sport: state.sports.firstWhere(
                          (Sport sport) => sport.id == booking.sportId),
                    ),
                  ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Open games',
              subtitle: 'Games your team can join today.',
              action: TextButton(
                onPressed: () => context.push(RoutePaths.games),
                child: const Text('See all'),
              ),
            ),
            const SizedBox(height: 12),
            if (openGames.isEmpty)
              const _EmptyPreview(title: 'No open games currently')
            else
              ...openGames.take(2).map(
                    (Game game) => _OpenGameCard(
                      game: game,
                      sport: state.sports.firstWhere(
                          (Sport sport) => sport.id == game.sportId),
                      venue: state.venues.firstWhere(
                          (Venue venue) => venue.id == game.venueId),
                      joined:
                          state.isPlayerActive(game.id, state.session.userId),
                      onTap: () => context.push('/games/${game.id}'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width > 600 ? 210 : double.infinity,
      child: FeatureCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onTap: onTap,
      ),
    );
  }
}

class _BookingPreview extends StatelessWidget {
  const _BookingPreview({
    required this.booking,
    required this.venue,
    required this.sport,
  });

  final Booking booking;
  final Venue venue;
  final Sport sport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${sport.name} at ${venue.name}'),
        subtitle: Text(
            '${formatDayMonth(booking.startAt)} · ${formatTimeRange(booking.startAt, booking.endAt)}'),
        trailing: Chip(label: Text(booking.status.label)),
      ),
    );
  }
}

class _OpenGameCard extends StatelessWidget {
  const _OpenGameCard({
    required this.game,
    required this.sport,
    required this.venue,
    required this.joined,
    required this.onTap,
  });

  final Game game;
  final Sport sport;
  final Venue venue;
  final bool joined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(game.title),
        subtitle: Text(
            '${sport.name} · ${venue.name} · ${formatTimeRange(game.startsAt, game.endsAt)}'),
        trailing: joined
            ? const Chip(
                avatar: Icon(Icons.check, size: 16, color: Colors.green),
                label: Text('Joined'),
                visualDensity: VisualDensity.compact,
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(title),
      ),
    );
  }
}
