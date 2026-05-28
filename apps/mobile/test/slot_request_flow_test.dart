import 'package:flutter_test/flutter_test.dart';

import 'package:playgrid_mobile/core/errors/app_failure.dart';
import 'package:playgrid_mobile/features/auth/data/local_playgrid_repository.dart';
import 'package:playgrid_mobile/features/auth/domain/playgrid_repository.dart';
import 'package:playgrid_mobile/shared/models/playgrid_mock_data.dart';
import 'package:playgrid_mobile/shared/models/playgrid_models.dart';

/// Coverage for the request → approve / auto-reject / notify flow exposed by
/// [LocalPlayGridRepository]. These tests pin the contract the admin
/// dashboard and tennis screen rely on.
void main() {
  const PlayGridSession member = PlayGridMockData.memberSession; // user-001
  const PlayGridSession priya = PlayGridSession(
    userId: 'user-002',
    email: 'priya@acme.com',
    isAuthenticated: true,
    profileComplete: true,
    role: UserRole.member,
  );
  const PlayGridSession kevin = PlayGridSession(
    userId: 'user-003',
    email: 'kevin@acme.com',
    isAuthenticated: true,
    profileComplete: true,
    role: UserRole.member,
  );
  const PlayGridSession admin = PlayGridSession(
    userId: PlayGridMockData.adminUserId,
    email: 'admin@playgrid.club',
    isAuthenticated: true,
    profileComplete: true,
    role: UserRole.admin,
  );

  late LocalPlayGridRepository repo;
  setUp(() => repo = LocalPlayGridRepository());

  /// Returns the id of an open future tennis slot that has no requests yet,
  /// so each test can claim a clean baseline without depending on the seed.
  Future<String> freshSlotId() async {
    final PlayGridState state = await repo.bootstrap(session: admin);
    final CourtSlot slot = state.courtSlots.firstWhere(
      (CourtSlot s) =>
          s.sportId == PlayGridMockData.tennisSportId &&
          s.isOpen &&
          s.startAt.isAfter(DateTime.now()) &&
          state.requestsForSlot(s.id).isEmpty,
      orElse: () =>
          throw StateError('No clean seed slot available — adjust seed.'),
    );
    return slot.id;
  }

  group('requestSlot', () {
    test('appends a pending request and notifies every admin', () async {
      final String slotId = await freshSlotId();
      final PlayGridState state = await repo.requestSlot(
        session: member,
        slotId: slotId,
        notes: 'Doubles practice',
      );
      final SlotRequest? req = state.requestBy(slotId, member.userId);
      expect(req, isNotNull);
      expect(req!.status, SlotRequestStatus.pending);
      expect(req.notes, 'Doubles practice');

      final bool adminNotified = state.notifications.any(
          (NotificationItem n) =>
              n.userId == PlayGridMockData.adminUserId &&
              n.title == 'New slot request');
      expect(adminNotified, isTrue,
          reason: 'Admins should receive a system notification.');
    });

    test('rejects a second request from the same user for the same slot',
        () async {
      final String slotId = await freshSlotId();
      await repo.requestSlot(
          session: member, slotId: slotId, notes: 'first');
      expect(
        () => repo.requestSlot(session: member, slotId: slotId, notes: 'dup'),
        throwsA(isA<AppFailure>()),
      );
    });

    test('rejects requests for past slots', () async {
      // Publish a slot that's already in the past.
      final DateTime past = DateTime.now().subtract(const Duration(hours: 2));
      await repo.addCourtSlots(
        session: admin,
        venueId: PlayGridMockData.tennisVenueId,
        sportId: PlayGridMockData.tennisSportId,
        startDate: past,
        endDate: past,
        startTimes: <TimeOfDayValue>[
          TimeOfDayValue(hour: past.hour, minute: 0),
        ],
        duration: const Duration(hours: 1),
      );
      // Because addCourtSlots refuses to create *truly* past entries via the
      // domain validator (it stores them anyway), we manually grab the matching
      // slot id and confirm the request layer guards.
      final PlayGridState afterAdd =
          await repo.bootstrap(session: admin);
      final CourtSlot pastSlot = afterAdd.courtSlots.firstWhere((CourtSlot s) =>
          s.startAt.isBefore(DateTime.now()) &&
          s.sportId == PlayGridMockData.tennisSportId);
      expect(
        () => repo.requestSlot(
            session: member, slotId: pastSlot.id, notes: ''),
        throwsA(isA<AppFailure>()),
      );
    });
  });

  group('approveSlotRequest', () {
    test('approves the chosen request and auto-rejects siblings when capacity '
        'is reached', () async {
      final String slotId = await freshSlotId();
      // Two members race for the same slot.
      await repo.requestSlot(session: member, slotId: slotId, notes: 'me');
      await repo.requestSlot(session: priya, slotId: slotId, notes: 'priya');
      PlayGridState state = await repo.bootstrap(session: admin);
      final SlotRequest mine = state.requestBy(slotId, member.userId)!;
      final SlotRequest other = state.requestBy(slotId, priya.userId)!;

      state = await repo.approveSlotRequest(
          session: admin, requestId: mine.id);

      // Mine approved.
      final SlotRequest approved = state.requestBy(slotId, member.userId)!;
      expect(approved.status, SlotRequestStatus.approved);
      expect(approved.decidedBy, admin.userId);

      // Sibling auto-rejected.
      final SlotRequest siblingAfter = state.requestBy(slotId, priya.userId)!;
      expect(siblingAfter.status, SlotRequestStatus.rejected);
      expect(siblingAfter.id, other.id);

      // Slot closed since capacity (1) is reached.
      final CourtSlot slot =
          state.courtSlots.firstWhere((CourtSlot s) => s.id == slotId);
      expect(slot.isOpen, isFalse);

      // Backing booking minted for the approved member.
      final bool hasBooking = state.bookings.any((Booking b) =>
          b.userId == member.userId &&
          b.startAt == slot.startAt &&
          b.status == BookingStatus.confirmed);
      expect(hasBooking, isTrue);

      // Approved member got a booking notification.
      final bool approvedNotif = state.notifications.any((NotificationItem n) =>
          n.userId == member.userId &&
          n.title == 'Request approved' &&
          !n.isRead);
      expect(approvedNotif, isTrue);

      // Rejected sibling got a 'not approved' notification.
      final bool rejectedNotif = state.notifications.any(
          (NotificationItem n) =>
              n.userId == priya.userId &&
              n.title == 'Request not approved');
      expect(rejectedNotif, isTrue);
    });

    test('refuses approval from a non-admin caller', () async {
      final String slotId = await freshSlotId();
      await repo.requestSlot(session: priya, slotId: slotId, notes: '');
      final PlayGridState state = await repo.bootstrap(session: priya);
      final SlotRequest req = state.requestBy(slotId, priya.userId)!;
      expect(
        () => repo.approveSlotRequest(session: member, requestId: req.id),
        throwsA(isA<AppFailure>()),
      );
    });
  });

  group('rejectSlotRequest', () {
    test('rejects a single pending request without touching siblings',
        () async {
      final String slotId = await freshSlotId();
      await repo.requestSlot(session: member, slotId: slotId, notes: 'me');
      await repo.requestSlot(session: kevin, slotId: slotId, notes: 'kev');
      PlayGridState state = await repo.bootstrap(session: admin);
      final SlotRequest mine = state.requestBy(slotId, member.userId)!;
      state = await repo.rejectSlotRequest(
          session: admin, requestId: mine.id, reason: 'Reserved');
      expect(state.requestBy(slotId, member.userId)!.status,
          SlotRequestStatus.rejected);
      expect(state.requestBy(slotId, kevin.userId)!.status,
          SlotRequestStatus.pending);
      final bool reasonInBody = state.notifications.any(
          (NotificationItem n) =>
              n.userId == member.userId && n.body.contains('Reserved'));
      expect(reasonInBody, isTrue);
    });
  });

  group('cancelSlotRequest', () {
    test('lets the requester withdraw a pending request', () async {
      final String slotId = await freshSlotId();
      await repo.requestSlot(session: priya, slotId: slotId, notes: '');
      final PlayGridState pre = await repo.bootstrap(session: priya);
      final SlotRequest req = pre.requestBy(slotId, priya.userId)!;
      final PlayGridState post = await repo.cancelSlotRequest(
          session: priya, requestId: req.id);
      expect(post.requestBy(slotId, priya.userId)!.status,
          SlotRequestStatus.cancelled);
    });

    test('blocks cancelling a request that belongs to someone else', () async {
      final String slotId = await freshSlotId();
      await repo.requestSlot(session: priya, slotId: slotId, notes: '');
      final PlayGridState state = await repo.bootstrap(session: priya);
      final SlotRequest req = state.requestBy(slotId, priya.userId)!;
      expect(
        () => repo.cancelSlotRequest(session: member, requestId: req.id),
        throwsA(isA<AppFailure>()),
      );
    });
  });

  group('addCourtSlots / removeCourtSlot', () {
    test('skips duplicates when admin re-publishes the same time', () async {
      final DateTime nextWeek =
          DateTime.now().add(const Duration(days: 7));
      final PlayGridState first = await repo.addCourtSlots(
        session: admin,
        venueId: PlayGridMockData.tennisVenueId,
        sportId: PlayGridMockData.tennisSportId,
        startDate: nextWeek,
        endDate: nextWeek,
        startTimes: const <TimeOfDayValue>[
          TimeOfDayValue(hour: 7, minute: 0),
        ],
        duration: const Duration(hours: 1),
      );
      final int countAfterFirst = first.courtSlots
          .where((CourtSlot s) =>
              s.startAt.year == nextWeek.year &&
              s.startAt.month == nextWeek.month &&
              s.startAt.day == nextWeek.day &&
              s.startAt.hour == 7)
          .length;
      expect(countAfterFirst, 1);

      final PlayGridState second = await repo.addCourtSlots(
        session: admin,
        venueId: PlayGridMockData.tennisVenueId,
        sportId: PlayGridMockData.tennisSportId,
        startDate: nextWeek,
        endDate: nextWeek,
        startTimes: const <TimeOfDayValue>[
          TimeOfDayValue(hour: 7, minute: 0),
        ],
        duration: const Duration(hours: 1),
      );
      final int countAfterSecond = second.courtSlots
          .where((CourtSlot s) =>
              s.startAt.year == nextWeek.year &&
              s.startAt.month == nextWeek.month &&
              s.startAt.day == nextWeek.day &&
              s.startAt.hour == 7)
          .length;
      expect(countAfterSecond, 1,
          reason: 'Republishing the same (date, time) should be a no-op.');
    });

    test('removing a slot cancels its pending requests and notifies them',
        () async {
      final String slotId = await freshSlotId();
      await repo.requestSlot(session: member, slotId: slotId, notes: '');
      final PlayGridState after =
          await repo.removeCourtSlot(session: admin, slotId: slotId);
      // Slot is gone.
      expect(after.courtSlots.any((CourtSlot s) => s.id == slotId), isFalse);
      // Request transitioned to cancelled.
      final SlotRequest req =
          after.slotRequests.firstWhere((SlotRequest r) => r.slotId == slotId);
      expect(req.status, SlotRequestStatus.cancelled);
      // Member notified.
      final bool notified = after.notifications.any((NotificationItem n) =>
          n.userId == member.userId && n.title == 'Slot removed');
      expect(notified, isTrue);
    });

    test('blocks slot management from non-admin callers', () async {
      expect(
        () => repo.addCourtSlots(
          session: member,
          venueId: PlayGridMockData.tennisVenueId,
          sportId: PlayGridMockData.tennisSportId,
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          startTimes: const <TimeOfDayValue>[
            TimeOfDayValue(hour: 9, minute: 0)
          ],
          duration: const Duration(hours: 1),
        ),
        throwsA(isA<AppFailure>()),
      );
    });
  });
}
