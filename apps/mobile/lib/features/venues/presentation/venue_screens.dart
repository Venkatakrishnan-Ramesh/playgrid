import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../../shared/widgets/user_picker.dart';
import '../../auth/domain/playgrid_controller.dart';

class VenueListScreen extends ConsumerStatefulWidget {
  const VenueListScreen({super.key});

  @override
  ConsumerState<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends ConsumerState<VenueListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final String q = _query.trim().toLowerCase();
    final List<Venue> venues = controller.state.venues.where((Venue venue) {
      if (q.isEmpty) {
        return true;
      }
      return venue.name.toLowerCase().contains(q) ||
          venue.location.toLowerCase().contains(q) ||
          venue.surfaceType.toLowerCase().contains(q);
    }).toList(growable: false);

    return MainShell(
      title: 'Venues',
      index: 1,
      body: Column(
        children: <Widget>[
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search venues, location, surface',
            ),
            onChanged: (String value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: venues.isEmpty
                  ? ListView(
                      children: const <Widget>[
                        SizedBox(height: 80),
                        Center(child: Text('No venues match your search.')),
                      ],
                    )
                  : ListView.separated(
                      itemCount: venues.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final Venue venue = venues[index];
                        return FeatureCard(
                          title: venue.name,
                          subtitle:
                              '${venue.location} · ${venue.surfaceType} · ${venue.capacity} pax',
                          icon: Icons.stadium_outlined,
                          onTap: () => context.push('/venues/${venue.id}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class VenueDetailScreen extends ConsumerWidget {
  const VenueDetailScreen({super.key, required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final Venue? venue = controller.state.venues
        .where((Venue value) => value.id == venueId)
        .firstOrNull;
    if (venue == null) {
      return const _NotFound(
          title: 'Venue', message: 'This venue is no longer available.');
    }
    final List<VenueSlot> slots = controller.state.venueSlots
        .where((VenueSlot slot) => slot.venueId == venueId)
        .toList();

    return AppShell(
      title: venue.name,
      actions: <Widget>[
        IconButton(
          onPressed: () => context.push(RoutePaths.bookings),
          icon: const Icon(Icons.book_online_outlined),
        ),
      ],
      body: ListView(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              venue.imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(Icons.stadium_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? progress) {
                if (progress == null) {
                  return child;
                }
                return Container(
                  height: 220,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(venue.location, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(venue.description),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Chip(label: Text(venue.surfaceType)),
              Chip(label: Text('${venue.capacity} pax')),
              const Chip(label: Text('RLS protected')),
            ],
          ),
          const SizedBox(height: 20),
          Text('Available slots',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...slots.map(
            (VenueSlot slot) => Card(
              child: ListTile(
                title: Text(slot.label),
                subtitle: Text(
                  '${formatDayMonth(slot.startAt)} · ${formatTimeRange(slot.startAt, slot.endAt)}',
                ),
                trailing: Icon(
                  slot.isAvailable
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
                  color: slot.isAvailable ? Colors.green : Colors.red,
                ),
                onTap: slot.isAvailable
                    ? () => context.push('/bookings/create/${venue.id}')
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/bookings/create/${venue.id}'),
            child: const Text('Create booking'),
          ),
        ],
      ),
    );
  }
}

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key, required this.venueId});

  final String venueId;

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final TextEditingController _notes =
      TextEditingController(text: 'Team practice');
  String? _selectedSlotId;
  String? _selectedSportId;
  bool _submitting = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final PlayGridController controller =
            ref.watch(playGridControllerProvider);
        final Venue? venue = controller.state.venues
            .where((Venue value) => value.id == widget.venueId)
            .firstOrNull;
        if (venue == null) {
          return const _NotFound(
              title: 'Booking', message: 'This venue is no longer available.');
        }
        final List<VenueSlot> slots = controller.state.venueSlots
            .where((VenueSlot slot) =>
                slot.venueId == widget.venueId && slot.isAvailable)
            .toList();
        final List<Sport> sports = controller.state.sports;
        _selectedSlotId ??= slots.isNotEmpty ? slots.first.id : null;
        _selectedSportId ??= sports.isNotEmpty ? sports.first.id : null;
        final bool canBook = _selectedSlotId != null && !_submitting;

        return AppShell(
          title: 'Book ${venue.name}',
          body: ListView(
            children: <Widget>[
              Text(venue.location,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              const Text('Pick a slot and sport for a confirmed booking.'),
              const SizedBox(height: 20),
              Text('Sport', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: sports
                    .map(
                      (Sport sport) => ChoiceChip(
                        label: Text(sport.name),
                        selected: _selectedSportId == sport.id,
                        onSelected: (_) =>
                            setState(() => _selectedSportId = sport.id),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text('Slots', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (slots.isEmpty)
                const Text('No available slots for this venue right now.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slots
                      .map(
                        (VenueSlot slot) => FilterChip(
                          label: Text(slot.label),
                          selected: _selectedSlotId == slot.id,
                          onSelected: (_) =>
                              setState(() => _selectedSlotId = slot.id),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed:
                    canBook ? () => _submit(context, controller, slots) : null,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirm booking'),
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
    List<VenueSlot> slots,
  ) async {
    final VenueSlot? slot =
        slots.where((VenueSlot item) => item.id == _selectedSlotId).firstOrNull;
    if (slot == null) {
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoRouter router = GoRouter.of(context);
    setState(() => _submitting = true);
    try {
      await controller.createBooking(
        venueId: widget.venueId,
        sportId: _selectedSportId ?? '',
        startAt: slot.startAt,
        endAt: slot.endAt,
        notes: _notes.text,
      );
      router.pushReplacement(RoutePaths.bookings);
      messenger.showSnackBar(
        const SnackBar(content: Text('Booking confirmed.')),
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

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final String me = state.session.userId;
    final List<Booking> active = state.upcomingBookingsFor(me);
    final List<Booking> shared = state.sharedBookingsFor(me);
    final List<Booking> cancelled = state.cancelledBookingsFor(me);

    return DefaultTabController(
      length: 3,
      child: AppShell(
        title: 'My Bookings',
        body: Column(
          children: <Widget>[
            const TabBar(
              tabs: <Widget>[
                Tab(text: 'Active'),
                Tab(text: 'Shared'),
                Tab(text: 'Cancelled'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _BookingList(
                    bookings: active,
                    state: state,
                    controller: controller,
                    tab: _BookingTab.active,
                    emptyMessage:
                        'No active bookings.\nReserve a slot from any venue to see it here.',
                  ),
                  _BookingList(
                    bookings: shared,
                    state: state,
                    controller: controller,
                    tab: _BookingTab.shared,
                    emptyMessage: 'No bookings shared with you yet.',
                  ),
                  _BookingList(
                    bookings: cancelled,
                    state: state,
                    controller: controller,
                    tab: _BookingTab.cancelled,
                    emptyMessage: 'No cancelled bookings.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BookingTab { active, shared, cancelled }

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.state,
    required this.controller,
    required this.tab,
    required this.emptyMessage,
  });

  final List<Booking> bookings;
  final PlayGridState state;
  final PlayGridController controller;
  final _BookingTab tab;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: bookings.isEmpty
          ? ListView(
              children: <Widget>[
                const SizedBox(height: 80),
                Center(
                  child: Text(emptyMessage, textAlign: TextAlign.center),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 12),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final Booking booking = bookings[index];
                final Venue venue = state.venues.byId(booking.venueId);
                final Sport sport = state.sports.byId(booking.sportId);
                final List<BookingParticipant> participants =
                    state.participantsOf(booking.id);
                final bool isShared = tab == _BookingTab.shared;
                return Card(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        title: Text('${sport.name} at ${venue.name}'),
                        subtitle: Text(
                          '${formatDayMonth(booking.startAt)} · ${formatTimeRange(booking.startAt, booking.endAt)}'
                          '${isShared ? '\nHosted by ${state.displayName(booking.userId)}' : ''}',
                        ),
                        isThreeLine: isShared,
                        trailing: _trailing(context, booking),
                      ),
                      if (tab != _BookingTab.cancelled &&
                          participants.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: participants
                                  .map((BookingParticipant p) => Chip(
                                        visualDensity: VisualDensity.compact,
                                        avatar:
                                            const Icon(Icons.person, size: 14),
                                        label:
                                            Text(state.displayName(p.userId)),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget? _trailing(BuildContext context, Booking booking) {
    switch (tab) {
      case _BookingTab.active:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Add players',
              onPressed: () => _addPlayers(context, booking),
            ),
            TextButton(
              onPressed: () => _confirmCancel(context, controller, booking),
              child: const Text('Cancel'),
            ),
          ],
        );
      case _BookingTab.shared:
        return TextButton(
          onPressed: () => controller.leaveSharedBooking(booking.id),
          child: const Text('Leave'),
        );
      case _BookingTab.cancelled:
        return Chip(label: Text(booking.status.label));
    }
  }

  Future<void> _addPlayers(BuildContext context, Booking booking) async {
    final Set<String> existing = state
        .participantsOf(booking.id)
        .map((BookingParticipant p) => p.userId)
        .toSet();
    final List<PickableUser> candidates = state.members
        .where((AppUserProfile m) =>
            m.id != booking.userId && !existing.contains(m.id))
        .map((AppUserProfile m) =>
            PickableUser(id: m.id, name: m.name, subtitle: m.department))
        .toList(growable: false);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final List<String>? selected = await showUserPicker(
      context: context,
      title: 'Add players to booking',
      confirmLabel: 'Add',
      candidates: candidates,
    );
    if (selected == null || selected.isEmpty) {
      return;
    }
    await controller.addBookingParticipants(booking.id, selected);
    messenger.showSnackBar(
      SnackBar(content: Text('Added ${selected.length} player(s).')),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    PlayGridController controller,
    Booking booking,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text(
            'This booking will be cancelled and removed from your active list.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await controller.cancelBooking(booking.id);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Booking cancelled and removed.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => controller.restoreBooking(booking.id),
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      body: Center(child: Text(message, textAlign: TextAlign.center)),
    );
  }
}
