import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/playgrid_mock_data.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../auth/domain/playgrid_controller.dart';
import '../../auth/domain/playgrid_repository.dart';

/// Top-level admin landing — exposes the request queue and slot manager.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final bool isAdmin =
        state.session.isAdmin || (state.profile?.isAdmin ?? false);

    if (!isAdmin) {
      return const AppShell(
        title: 'Admin',
        body: Center(child: Text('Admin access required')),
      );
    }

    final int pendingCount = state.slotRequests
        .where((SlotRequest r) => r.isPending)
        .length;

    return AppShell(
      title: 'Admin dashboard',
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          children: <Widget>[
            Text(
              'Court operations',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FeatureCard(
              title: pendingCount == 0
                  ? 'Slot requests'
                  : 'Slot requests · $pendingCount pending',
              subtitle: pendingCount == 0
                  ? 'No requests waiting on you right now.'
                  : 'Approve one, auto-reject the rest. Members get notified.',
              icon: Icons.inbox_outlined,
              onTap: () => context.push(RoutePaths.adminRequests),
            ),
            const SizedBox(height: 12),
            FeatureCard(
              title: 'Manage tennis slots',
              subtitle:
                  'Calendar view of every slot — tap a day to see who booked '
                  'it, plus a publisher for new dates.',
              icon: Icons.calendar_month_outlined,
              onTap: () => context.push(RoutePaths.adminSlots),
            ),
            const SizedBox(height: 12),
            FeatureCard(
              title: 'Manage venues',
              subtitle: 'Add, edit, and review venue inventory.',
              icon: Icons.storefront_outlined,
              onTap: () => context.push(RoutePaths.adminVenues),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Slot requests queue
// ============================================================================

class AdminSlotRequestsScreen extends ConsumerWidget {
  const AdminSlotRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    if (!_isAdmin(state)) {
      return const AppShell(
        title: 'Slot requests',
        body: Center(child: Text('Admin access required')),
      );
    }

    final List<CourtSlot> contestedSlots = state.slotsAwaitingAdmin();

    return AppShell(
      title: 'Slot requests',
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: contestedSlots.isEmpty
            ? ListView(
                children: const <Widget>[
                  SizedBox(height: 80),
                  Center(child: Text('All caught up — no pending requests.')),
                ],
              )
            : ListView.separated(
                itemCount: contestedSlots.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  final CourtSlot slot = contestedSlots[index];
                  return _SlotRequestGroup(
                    slot: slot,
                    state: state,
                    controller: controller,
                  );
                },
              ),
      ),
    );
  }
}

class _SlotRequestGroup extends StatelessWidget {
  const _SlotRequestGroup({
    required this.slot,
    required this.state,
    required this.controller,
  });

  final CourtSlot slot;
  final PlayGridState state;
  final PlayGridController controller;

  @override
  Widget build(BuildContext context) {
    final List<SlotRequest> pending = state.pendingRequestsForSlot(slot.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${DateFormatters.shortDate(slot.startAt)} · '
                        '${slot.label}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        formatTimeRange(slot.startAt, slot.endAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(label: Text('${pending.length} pending')),
              ],
            ),
            const SizedBox(height: 12),
            ...pending.map((SlotRequest req) => _PendingRequestTile(
                  request: req,
                  state: state,
                  controller: controller,
                  slot: slot,
                )),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestTile extends StatelessWidget {
  const _PendingRequestTile({
    required this.request,
    required this.state,
    required this.controller,
    required this.slot,
  });

  final SlotRequest request;
  final PlayGridState state;
  final PlayGridController controller;
  final CourtSlot slot;

  @override
  Widget build(BuildContext context) {
    final AppUserProfile? user = state.memberById(request.userId);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                ? NetworkImage(user!.avatarUrl)
                : null,
            child: (user?.avatarUrl.isEmpty ?? true)
                ? Text((user?.name.isNotEmpty ?? false)
                    ? user!.name[0].toUpperCase()
                    : '?')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user?.name ?? 'Member',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if ((user?.department.isNotEmpty ?? false))
                  Text(
                    user!.department,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (request.notes.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text('"${request.notes}"',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 6),
                Text(
                  'Requested ${DateFormatters.dateTime(request.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      onPressed: () =>
                          _approve(context, controller, request, slot),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      onPressed: () =>
                          _reject(context, controller, request, slot),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    PlayGridController controller,
    SlotRequest request,
    CourtSlot slot,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final int otherPending = state.pendingRequestsForSlot(slot.id).length - 1;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Approve this request?'),
        content: Text(otherPending <= 0
            ? 'A booking will be created for this member.'
            : 'Approving will create the booking and automatically reject '
                'the other $otherPending request${otherPending == 1 ? '' : 's'} '
                'for this slot.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Approve')),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await controller.approveSlotRequest(request.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Approved.')),
      );
    } on AppFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _reject(
    BuildContext context,
    PlayGridController controller,
    SlotRequest request,
    CourtSlot slot,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TextEditingController reason = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Reject this request?'),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Shown to the member in the notification.',
          ),
          maxLines: 2,
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Cancel')),
          FilledButton.tonal(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await controller.rejectSlotRequest(request.id, reason: reason.text);
      messenger.showSnackBar(
        const SnackBar(content: Text('Rejected.')),
      );
    } on AppFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

// ============================================================================
// Slot manager — Calendar + Publish tabs
// ============================================================================

class AdminSlotManagerScreen extends ConsumerWidget {
  const AdminSlotManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    if (!_isAdmin(state)) {
      return const AppShell(
        title: 'Tennis slots',
        body: Center(child: Text('Admin access required')),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tennis slots'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Calendar', icon: Icon(Icons.calendar_month_outlined)),
              Tab(text: 'Publish', icon: Icon(Icons.add_box_outlined)),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: <Widget>[
              _AdminSlotCalendarTab(),
              _AdminPublishSlotsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------- Calendar tab ----------------------------------------------

class _AdminSlotCalendarTab extends ConsumerStatefulWidget {
  const _AdminSlotCalendarTab();

  @override
  ConsumerState<_AdminSlotCalendarTab> createState() =>
      _AdminSlotCalendarTabState();
}

class _AdminSlotCalendarTabState extends ConsumerState<_AdminSlotCalendarTab> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    final DateTime today = _dayOnly(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
  }

  @override
  Widget build(BuildContext context) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final Map<DateTime, List<CourtSlot>> byDay =
        _groupSlotsByDay(state.courtSlots);
    final List<CourtSlot> daySlots =
        byDay[_dayOnly(_selectedDay)] ?? const <CourtSlot>[];

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            margin: EdgeInsets.zero,
            child: TableCalendar<CourtSlot>(
              firstDay: _dayOnly(DateTime.now())
                  .subtract(const Duration(days: 60)),
              lastDay:
                  _dayOnly(DateTime.now()).add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (DateTime day) =>
                  isSameDay(day, _selectedDay),
              calendarFormat: _format,
              availableCalendarFormats: const <CalendarFormat, String>{
                CalendarFormat.month: 'Month',
                CalendarFormat.twoWeeks: '2 weeks',
                CalendarFormat.week: 'Week',
              },
              eventLoader: (DateTime day) =>
                  byDay[_dayOnly(day)] ?? const <CourtSlot>[],
              onDaySelected: (DateTime selected, DateTime focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onFormatChanged: (CalendarFormat f) =>
                  setState(() => _format = f),
              onPageChanged: (DateTime focused) => _focusedDay = focused,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
                markerSize: 6,
              ),
              headerStyle: const HeaderStyle(
                formatButtonShowsNext: false,
                titleCentered: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormatters.shortDate(_selectedDay),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            daySlots.isEmpty
                ? 'No slots on this date. Publish some from the Publish tab.'
                : '${daySlots.length} slot${daySlots.length == 1 ? '' : 's'} '
                    '· tap to expand booking details.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 12),
          ...daySlots.map(
            (CourtSlot slot) => _AdminSlotExpansionTile(
              slot: slot,
              state: state,
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<DateTime, List<CourtSlot>> _groupSlotsByDay(List<CourtSlot> all) {
    final Map<DateTime, List<CourtSlot>> map =
        <DateTime, List<CourtSlot>>{};
    for (final CourtSlot slot in all) {
      if (slot.sportId != PlayGridMockData.tennisSportId) {
        continue;
      }
      final DateTime key = _dayOnly(slot.startAt);
      map.putIfAbsent(key, () => <CourtSlot>[]).add(slot);
    }
    for (final List<CourtSlot> day in map.values) {
      day.sort((CourtSlot a, CourtSlot b) => a.startAt.compareTo(b.startAt));
    }
    return map;
  }
}

class _AdminSlotExpansionTile extends StatelessWidget {
  const _AdminSlotExpansionTile({
    required this.slot,
    required this.state,
    required this.controller,
  });

  final CourtSlot slot;
  final PlayGridState state;
  final PlayGridController controller;

  @override
  Widget build(BuildContext context) {
    final List<SlotRequest> approved = state.approvedRequestsForSlot(slot.id);
    final List<SlotRequest> pending = state.pendingRequestsForSlot(slot.id);
    final bool isPast = slot.startAt.isBefore(DateTime.now());

    final List<String> tags = <String>[
      formatTimeRange(slot.startAt, slot.endAt),
      'capacity ${slot.capacity}',
      if (approved.isNotEmpty) '${approved.length} booked',
      if (pending.isNotEmpty) '${pending.length} pending',
      if (!slot.isOpen) 'closed',
      if (isPast) 'past',
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: approved.isNotEmpty
              ? Colors.green.shade100
              : pending.isNotEmpty
                  ? Colors.orange.shade100
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            approved.isNotEmpty
                ? Icons.check
                : pending.isNotEmpty
                    ? Icons.hourglass_top
                    : Icons.event_available_outlined,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        title: Text(slot.label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(tags.join(' · ')),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _BookedByList(approved: approved, state: state),
                if (pending.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text('Pending requests',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  ...pending.map((SlotRequest r) => _PendingMiniRow(
                        request: r,
                        state: state,
                      )),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push(RoutePaths.adminRequests),
                    icon: const Icon(Icons.inbox_outlined),
                    label: const Text('Review in requests queue'),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    label: const Text('Remove this slot'),
                    onPressed: () => _confirmRemove(context, controller, slot,
                        approved: approved.length, pending: pending.length),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    PlayGridController controller,
    CourtSlot slot, {
    required int approved,
    required int pending,
  }) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Remove this slot?'),
        content: Text(approved > 0
            ? 'A member already has a confirmed booking — removing will '
                'cancel it and notify them.'
            : pending > 0
                ? '$pending pending request${pending == 1 ? '' : 's'} will be '
                    'cancelled and the member${pending == 1 ? '' : 's'} '
                    'notified.'
                : 'This slot has no requests. Safe to remove.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Keep')),
          FilledButton.tonal(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await controller.removeCourtSlot(slot.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Slot removed.')),
      );
    } on AppFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _BookedByList extends StatelessWidget {
  const _BookedByList({required this.approved, required this.state});

  final List<SlotRequest> approved;
  final PlayGridState state;

  @override
  Widget build(BuildContext context) {
    if (approved.isEmpty) {
      return Text(
        'No bookings yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Booked by', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        ...approved.map((SlotRequest r) {
          final AppUserProfile? user = state.memberById(r.userId);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 16,
                  backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                      ? NetworkImage(user!.avatarUrl)
                      : null,
                  child: (user?.avatarUrl.isEmpty ?? true)
                      ? Text((user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : '?')
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user?.name ?? 'Member',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (r.notes.isNotEmpty)
                        Text('"${r.notes}"',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline,
                                    )),
                    ],
                  ),
                ),
                const Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('Approved'),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PendingMiniRow extends StatelessWidget {
  const _PendingMiniRow({required this.request, required this.state});

  final SlotRequest request;
  final PlayGridState state;

  @override
  Widget build(BuildContext context) {
    final AppUserProfile? user = state.memberById(request.userId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 12,
            backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                ? NetworkImage(user!.avatarUrl)
                : null,
            child: (user?.avatarUrl.isEmpty ?? true)
                ? Text(
                    (user?.name.isNotEmpty ?? false)
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 10),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(user?.name ?? 'Member')),
          if (request.notes.isNotEmpty)
            Flexible(
              child: Text(
                '"${request.notes}"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

// --------------- Publish tab ------------------------------------------------

class _AdminPublishSlotsTab extends ConsumerStatefulWidget {
  const _AdminPublishSlotsTab();

  @override
  ConsumerState<_AdminPublishSlotsTab> createState() =>
      _AdminPublishSlotsTabState();
}

class _AdminPublishSlotsTabState
    extends ConsumerState<_AdminPublishSlotsTab> {
  static const List<TimeOfDayValue> _allOptions = <TimeOfDayValue>[
    TimeOfDayValue(hour: 7, minute: 0),
    TimeOfDayValue(hour: 8, minute: 0),
    TimeOfDayValue(hour: 9, minute: 0),
    TimeOfDayValue(hour: 16, minute: 0),
    TimeOfDayValue(hour: 17, minute: 0),
    TimeOfDayValue(hour: 18, minute: 0),
    TimeOfDayValue(hour: 19, minute: 0),
    TimeOfDayValue(hour: 20, minute: 0),
    TimeOfDayValue(hour: 21, minute: 0),
  ];

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  Duration _duration = const Duration(hours: 1);
  int _capacity = 1;
  final Set<TimeOfDayValue> _selectedTimes = <TimeOfDayValue>{
    const TimeOfDayValue(hour: 18, minute: 0),
    const TimeOfDayValue(hour: 19, minute: 0),
  };

  @override
  Widget build(BuildContext context) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Publish slots',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          'Creates one slot per selected start time × every day in the '
          'date range. Existing slots are skipped automatically.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 16),
        _DateRow(
          label: 'Start date',
          value: _startDate,
          onPick: (DateTime picked) => setState(() {
            _startDate = picked;
            if (_endDate.isBefore(picked)) {
              _endDate = picked;
            }
          }),
        ),
        const SizedBox(height: 8),
        _DateRow(
          label: 'End date',
          value: _endDate,
          onPick: (DateTime picked) => setState(() => _endDate = picked),
        ),
        const SizedBox(height: 16),
        Text('Start times', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allOptions.map((TimeOfDayValue t) {
            final bool selected = _selectedTimes.contains(t);
            return FilterChip(
              label: Text(_formatTime(t)),
              selected: selected,
              onSelected: (bool value) {
                setState(() {
                  if (value) {
                    _selectedTimes.add(t);
                  } else {
                    _selectedTimes.remove(t);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _duration.inMinutes,
                decoration: const InputDecoration(labelText: 'Duration'),
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(value: 30, child: Text('30 minutes')),
                  DropdownMenuItem<int>(value: 60, child: Text('1 hour')),
                  DropdownMenuItem<int>(value: 90, child: Text('1.5 hours')),
                  DropdownMenuItem<int>(value: 120, child: Text('2 hours')),
                ],
                onChanged: (int? minutes) {
                  if (minutes != null) {
                    setState(() => _duration = Duration(minutes: minutes));
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _capacity,
                decoration: const InputDecoration(labelText: 'Capacity'),
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(value: 1, child: Text('1 booking')),
                  DropdownMenuItem<int>(value: 2, child: Text('2 bookings')),
                  DropdownMenuItem<int>(value: 4, child: Text('4 bookings')),
                ],
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() => _capacity = value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _selectedTimes.isEmpty
              ? null
              : () => _publish(context, controller),
          icon: const Icon(Icons.publish_outlined),
          label: const Text('Publish slots'),
        ),
        const SizedBox(height: 12),
        if (controller.state.message.isNotEmpty)
          Text(controller.state.message,
              style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Future<void> _publish(
    BuildContext context,
    PlayGridController controller,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await controller.addCourtSlots(
        venueId: PlayGridMockData.tennisVenueId,
        sportId: PlayGridMockData.tennisSportId,
        startDate: _startDate,
        endDate: _endDate,
        startTimes: _selectedTimes.toList(growable: false),
        duration: _duration,
        capacity: _capacity,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(controller.state.message)),
      );
    } on AppFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  static String _formatTime(TimeOfDayValue t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            '$label: ${DateFormatters.shortDate(value)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.event),
          label: const Text('Pick'),
          onPressed: () async {
            final DateTime now = DateTime.now();
            final DateTime first = DateTime(now.year, now.month, now.day);
            final DateTime initial = value.isBefore(first) ? first : value;
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: first,
              lastDate: first.add(const Duration(days: 365)),
            );
            if (picked != null) {
              onPick(picked);
            }
          },
        ),
      ],
    );
  }
}

class ManageVenuesScreen extends StatelessWidget {
  const ManageVenuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Manage venues',
      body: Center(
        child: Text(
            'Add/edit venue placeholder and blocked slot management will live here.'),
      ),
    );
  }
}

bool _isAdmin(PlayGridState state) =>
    state.session.isAdmin || (state.profile?.isAdmin ?? false);
