import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

class VenueListScreen extends ConsumerWidget {
  const VenueListScreen({super.key});

  @override
  Widget buildWithRef(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final List<Venue> venues = controller.state.venues;

    return MainShell(
      title: 'Venues',
      index: 1,
      body: ListView.separated(
        itemCount: venues.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final Venue venue = venues[index];
          return FeatureCard(
            title: venue.name,
            subtitle:
                '${venue.location} · ${venue.surfaceType} · ${venue.capacity} pax',
            icon: Icons.stadium_outlined,
            onTap: () => context.go('/venues/${venue.id}'),
          );
        },
      ),
    );
  }
}

class VenueDetailScreen extends ConsumerWidget {
  const VenueDetailScreen({super.key, required this.venueId});

  final String venueId;

  @override
  Widget buildWithRef(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final Venue venue = controller.state.venues
        .firstWhere((Venue value) => value.id == venueId);
    final List<VenueSlot> slots = controller.state.venueSlots
        .where((VenueSlot slot) => slot.venueId == venueId)
        .toList();

    return AppShell(
      title: venue.name,
      actions: <Widget>[
        IconButton(
          onPressed: () => context.go(RoutePaths.bookings),
          icon: const Icon(Icons.book_online_outlined),
        ),
      ],
      body: ListView(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child:
                Image.network(venue.imageUrl, height: 220, fit: BoxFit.cover),
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
                    ? () => context.go('/bookings/create/${venue.id}')
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/bookings/create/${venue.id}'),
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
        final Venue venue = controller.state.venues
            .firstWhere((Venue value) => value.id == widget.venueId);
        final List<VenueSlot> slots = controller.state.venueSlots
            .where((VenueSlot slot) =>
                slot.venueId == widget.venueId && slot.isAvailable)
            .toList();
        final List<Sport> sports = controller.state.sports;
        _selectedSlotId ??= slots.isNotEmpty ? slots.first.id : null;
        _selectedSportId ??= sports.isNotEmpty ? sports.first.id : null;

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
                onPressed: () async {
                  final VenueSlot slot = slots.firstWhere(
                      (VenueSlot item) => item.id == _selectedSlotId);
                  await controller.createBooking(
                    venueId: widget.venueId,
                    sportId: _selectedSportId ?? sports.first.id,
                    startAt: slot.startAt,
                    endAt: slot.endAt,
                    notes: _notes.text,
                  );
                  if (!context.mounted) {
                    return;
                  }
                  context.go(RoutePaths.bookings);
                },
                child: const Text('Confirm booking'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget buildWithRef(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final List<Booking> bookings =
        state.upcomingBookingsFor(state.session.userId);

    return AppShell(
      title: 'My Bookings',
      body: ListView.separated(
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final Booking booking = bookings[index];
          final Venue venue = state.venues
              .firstWhere((Venue value) => value.id == booking.venueId);
          final Sport sport = state.sports
              .firstWhere((Sport value) => value.id == booking.sportId);
          return Card(
            child: ListTile(
              title: Text('${sport.name} at ${venue.name}'),
              subtitle: Text(
                '${formatDayMonth(booking.startAt)} · ${formatTimeRange(booking.startAt, booking.endAt)}',
              ),
              trailing: TextButton(
                onPressed: booking.status == BookingStatus.cancelled
                    ? null
                    : () async {
                        await controller.cancelBooking(booking.id);
                      },
                child: const Text('Cancel'),
              ),
            ),
          );
        },
      ),
    );
  }
}
