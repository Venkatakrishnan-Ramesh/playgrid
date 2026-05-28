import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/playgrid_mock_data.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

/// Member-facing tennis screen.
///
/// Layout: month calendar at the top with a marker dot on every day that has
/// at least one published slot. Tapping a day drills into that day's slot
/// list with request / cancel actions. A recent-requests timeline lives
/// below for visibility into pending decisions.
class TennisBookingScreen extends ConsumerStatefulWidget {
  const TennisBookingScreen({super.key});

  @override
  ConsumerState<TennisBookingScreen> createState() =>
      _TennisBookingScreenState();
}

class _TennisBookingScreenState extends ConsumerState<TennisBookingScreen> {
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
    final String me = state.session.userId;

    final Map<DateTime, List<CourtSlot>> slotsByDay =
        _groupSlotsByDay(state.courtSlots);

    final List<CourtSlot> slotsForSelectedDay =
        slotsByDay[_dayOnly(_selectedDay)] ?? const <CourtSlot>[];
    final List<SlotRequest> myRequests = state.requestsByUser(me);

    return AppShell(
      title: 'Tennis bookings',
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Card(
              margin: EdgeInsets.zero,
              child: TableCalendar<CourtSlot>(
                firstDay: _dayOnly(DateTime.now())
                    .subtract(const Duration(days: 14)),
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
                    slotsByDay[_dayOnly(day)] ?? const <CourtSlot>[],
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
            _SectionHeader(
              title: DateFormatters.shortDate(_selectedDay),
              caption: slotsForSelectedDay.isEmpty
                  ? 'No slots published for this day yet.'
                  : 'Tap a slot to request it. Admin approves one request '
                      'per slot.',
            ),
            const SizedBox(height: 12),
            if (slotsForSelectedDay.isEmpty)
              const _EmptyState(
                message: 'Nothing on this date. Pick a day with a dot below '
                    'the number, or pull to refresh.',
              )
            else
              ...slotsForSelectedDay.map((CourtSlot slot) => _SlotCard(
                    slot: slot,
                    state: state,
                    currentUserId: me,
                    onRequest: () => _showRequestSheet(
                      context,
                      controller,
                      slot: slot,
                    ),
                    onCancel: (SlotRequest request) =>
                        _cancelRequest(context, controller, request),
                  )),
            const SizedBox(height: 28),
            const _SectionHeader(
              title: 'My recent requests',
              caption:
                  'Approvals, rejections, and pending reviews — newest first.',
            ),
            const SizedBox(height: 12),
            if (myRequests.isEmpty)
              const _EmptyState(
                message:
                    'You have not requested any slots yet. Pick one above '
                    'to get started.',
              )
            else
              ...myRequests.map((SlotRequest r) => _RequestSummaryCard(
                    request: r,
                    slot: _findSlot(state, r.slotId),
                    onCancel: r.isPending
                        ? () => _cancelRequest(context, controller, r)
                        : null,
                  )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Index slots by the local-day key so the calendar's eventLoader can do
  /// O(1) lookups instead of re-scanning the whole list on every cell.
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

  CourtSlot? _findSlot(PlayGridState state, String slotId) {
    for (final CourtSlot s in state.courtSlots) {
      if (s.id == slotId) {
        return s;
      }
    }
    return null;
  }

  Future<void> _showRequestSheet(
    BuildContext context,
    PlayGridController controller, {
    required CourtSlot slot,
  }) async {
    final TextEditingController notes = TextEditingController();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Request ${slot.label}',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(DateFormatters.shortDate(slot.startAt),
                  style: Theme.of(sheetContext).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes for admin (optional)',
                  hintText: 'e.g. doubles with the design team',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: const Text('Send request'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await controller.requestSlot(slotId: slot.id, notes: notes.text);
      messenger.showSnackBar(
        const SnackBar(content: Text('Request sent. Waiting for admin.')),
      );
    } on AppFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _cancelRequest(
    BuildContext context,
    PlayGridController controller,
    SlotRequest request,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await controller.cancelSlotRequest(request.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Request cancelled.')),
      );
    } on AppFailure catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(caption,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.state,
    required this.currentUserId,
    required this.onRequest,
    required this.onCancel,
  });

  final CourtSlot slot;
  final PlayGridState state;
  final String currentUserId;
  final VoidCallback onRequest;
  final ValueChanged<SlotRequest> onCancel;

  @override
  Widget build(BuildContext context) {
    final SlotRequest? mine = state.requestBy(slot.id, currentUserId);
    final List<SlotRequest> pendingOthers = state
        .pendingRequestsForSlot(slot.id)
        .where((SlotRequest r) => r.userId != currentUserId)
        .toList(growable: false);
    final List<SlotRequest> approved = state.approvedRequestsForSlot(slot.id);
    final bool isPast = slot.startAt.isBefore(DateTime.now());
    final bool isClosed = !slot.isOpen;
    final int pendingCount =
        pendingOthers.length + (mine?.isPending == true ? 1 : 0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    slot.label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (isPast)
                  const Chip(label: Text('Past'))
                else if (isClosed)
                  const Chip(label: Text('Closed'))
                else if (approved.isNotEmpty)
                  const Chip(
                    label: Text('Booked'),
                    backgroundColor: Color(0xFFE6F4EA),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${formatTimeRange(slot.startAt, slot.endAt)} · '
              '$pendingCount pending request${pendingCount == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (mine == null && !isPast && !isClosed)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onRequest,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Request slot'),
                ),
              )
            else if (mine != null)
              _MyRequestState(request: mine, onCancel: () => onCancel(mine)),
          ],
        ),
      ),
    );
  }
}

class _MyRequestState extends StatelessWidget {
  const _MyRequestState({required this.request, required this.onCancel});

  final SlotRequest request;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    switch (request.status) {
      case SlotRequestStatus.pending:
        return Row(
          children: <Widget>[
            const Chip(
              avatar: Icon(Icons.hourglass_top, size: 16),
              label: Text('Your request: pending'),
            ),
            const Spacer(),
            TextButton(
                onPressed: onCancel, child: const Text('Cancel request')),
          ],
        );
      case SlotRequestStatus.approved:
        return const Chip(
          avatar: Icon(Icons.check_circle, color: Colors.green, size: 16),
          label: Text('Approved — see My Bookings'),
        );
      case SlotRequestStatus.rejected:
        return const Chip(
          avatar: Icon(Icons.cancel, color: Colors.red, size: 16),
          label: Text('Rejected'),
        );
      case SlotRequestStatus.cancelled:
        return const Chip(
          avatar: Icon(Icons.remove_circle_outline, size: 16),
          label: Text('Cancelled'),
        );
    }
  }
}

class _RequestSummaryCard extends StatelessWidget {
  const _RequestSummaryCard({
    required this.request,
    required this.slot,
    required this.onCancel,
  });

  final SlotRequest request;
  final CourtSlot? slot;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final String title = slot == null
        ? 'Removed slot'
        : '${DateFormatters.shortDate(slot!.startAt)} · ${slot!.label}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: _StatusIcon(status: request.status),
        title: Text(title),
        subtitle: Text(
          'Status: ${request.status.label}'
          '${request.notes.isEmpty ? '' : '\n"${request.notes}"'}',
        ),
        isThreeLine: request.notes.isNotEmpty,
        trailing: onCancel == null
            ? null
            : TextButton(onPressed: onCancel, child: const Text('Cancel')),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final SlotRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    switch (status) {
      case SlotRequestStatus.pending:
        icon = Icons.hourglass_top;
        color = Colors.orange;
      case SlotRequestStatus.approved:
        icon = Icons.check_circle;
        color = Colors.green;
      case SlotRequestStatus.rejected:
        icon = Icons.cancel;
        color = Colors.red;
      case SlotRequestStatus.cancelled:
        icon = Icons.remove_circle_outline;
        color = Theme.of(context).colorScheme.outline;
    }
    return Icon(icon, color: color);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
