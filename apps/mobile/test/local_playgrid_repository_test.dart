import 'package:flutter_test/flutter_test.dart';

import 'package:playgrid_mobile/core/errors/app_failure.dart';
import 'package:playgrid_mobile/features/auth/data/local_playgrid_repository.dart';
import 'package:playgrid_mobile/shared/models/playgrid_mock_data.dart';
import 'package:playgrid_mobile/shared/models/playgrid_models.dart';

/// Functional + regression coverage for the in-memory repository that backs
/// the mock/demo mode and encodes the app's core business rules (booking
/// conflicts, game waitlists, group ownership, friend requests, notifications).
///
/// Each test constructs a fresh [LocalPlayGridRepository] so seeded mock data
/// is isolated and the suite has no inter-test ordering dependencies.
void main() {
  const PlayGridSession member = PlayGridMockData.memberSession; // user-001

  // Sessions for other seeded members, used to exercise multi-user flows.
  const PlayGridSession priya = PlayGridSession(
    userId: 'user-002',
    email: 'priya@acme.com',
    isAuthenticated: true,
    profileComplete: true,
    role: UserRole.member,
  );

  late LocalPlayGridRepository repo;

  setUp(() => repo = LocalPlayGridRepository());

  group('bootstrap', () {
    test('hydrates seeded collections for an authenticated member', () async {
      final state = await repo.bootstrap(session: member);

      expect(state.profile, isNotNull);
      expect(state.sports, isNotEmpty);
      expect(state.venues, isNotEmpty);
      expect(state.games, isNotEmpty);
      expect(state.loading, isFalse);
    });

    test('returns no profile for a guest session', () async {
      final state = await repo.bootstrap(session: PlayGridMockData.guestSession);

      expect(state.profile, isNull);
      expect(state.message, 'Ready to sign in.');
    });
  });

  group('bookings', () {
    test('creates a confirmed booking for a free slot', () async {
      final state = await repo.createBooking(
        session: member,
        venueId: 'venue-lane',
        sportId: 'sport-badminton',
        startAt: DateTime(2026, 5, 25, 10, 0),
        endAt: DateTime(2026, 5, 25, 11, 0),
        notes: 'Practice',
      );

      final created = state.bookings.where((b) => b.venueId == 'venue-lane');
      expect(created, hasLength(1));
      expect(created.first.status, BookingStatus.confirmed);
      expect(created.first.userId, member.userId);
    });

    test('rejects a slot overlapping an existing confirmed booking', () {
      // booking-1: venue-alpha, 2026-05-20 18:00-19:00, confirmed.
      expect(
        () => repo.createBooking(
          session: member,
          venueId: 'venue-alpha',
          sportId: 'sport-badminton',
          startAt: DateTime(2026, 5, 20, 18, 30),
          endAt: DateTime(2026, 5, 20, 19, 30),
          notes: 'Overlaps',
        ),
        throwsA(isA<AppFailure>()),
      );
    });

    test('allows a slot that only overlaps a cancelled booking', () async {
      await repo.cancelBooking(session: member, bookingId: 'booking-1');

      final state = await repo.createBooking(
        session: member,
        venueId: 'venue-alpha',
        sportId: 'sport-badminton',
        startAt: DateTime(2026, 5, 20, 18, 0),
        endAt: DateTime(2026, 5, 20, 19, 0),
        notes: 'Re-books the freed slot',
      );

      final confirmedAtAlpha = state.bookings.where((b) =>
          b.venueId == 'venue-alpha' && b.status == BookingStatus.confirmed);
      expect(confirmedAtAlpha, hasLength(1));
    });

    test('cancel then restore round-trips the booking status', () async {
      final cancelled =
          await repo.cancelBooking(session: member, bookingId: 'booking-1');
      expect(
        cancelled.bookings.firstWhere((b) => b.id == 'booking-1').status,
        BookingStatus.cancelled,
      );

      final restored =
          await repo.restoreBooking(session: member, bookingId: 'booking-1');
      expect(
        restored.bookings.firstWhere((b) => b.id == 'booking-1').status,
        BookingStatus.confirmed,
      );
    });

    test('cannot cancel a booking owned by another member', () {
      // booking-2 is owned by user-002.
      expect(
        () => repo.cancelBooking(session: member, bookingId: 'booking-2'),
        throwsA(isA<AppFailure>()),
      );
    });

    test('cancelling an unknown booking fails', () {
      expect(
        () => repo.cancelBooking(session: member, bookingId: 'nope'),
        throwsA(isA<AppFailure>()),
      );
    });
  });

  group('games', () {
    test('createGame adds an open, waitlist-enabled game', () async {
      final state = await repo.createGame(
        session: member,
        title: 'Lunch Football',
        description: '5-a-side',
        sportId: 'sport-football',
        venueId: 'venue-ridge',
        startsAt: DateTime(2026, 6, 1, 13, 0),
        endsAt: DateTime(2026, 6, 1, 14, 0),
        maxPlayers: 10,
      );

      final created = state.games.firstWhere((g) => g.title == 'Lunch Football');
      expect(created.status, GameStatus.open);
      expect(created.waitlistEnabled, isTrue);
      expect(created.createdBy, member.userId);
    });

    test('joining a full game waitlists, and leaving promotes the next', () async {
      // One-seat game so the second joiner is forced onto the waitlist.
      final created = await repo.createGame(
        session: member,
        title: 'Singles Court',
        description: '1v1',
        sportId: 'sport-badminton',
        venueId: 'venue-lane',
        startsAt: DateTime(2026, 6, 2, 18, 0),
        endsAt: DateTime(2026, 6, 2, 19, 0),
        maxPlayers: 1,
      );
      final gameId = created.games.firstWhere((g) => g.title == 'Singles Court').id;

      final afterOwner = await repo.joinGame(session: member, gameId: gameId);
      expect(afterOwner.playerStatusFor(gameId, member.userId),
          PlayerStatus.joined);

      final afterPriya = await repo.joinGame(session: priya, gameId: gameId);
      expect(afterPriya.playerStatusFor(gameId, priya.userId),
          PlayerStatus.waitlisted);

      // Owner leaves → the waitlisted player is promoted to joined.
      final afterLeave = await repo.leaveGame(session: member, gameId: gameId);
      expect(afterLeave.playerStatusFor(gameId, member.userId), isNull);
      expect(afterLeave.playerStatusFor(gameId, priya.userId),
          PlayerStatus.joined);
    });

    test('joining a game twice is idempotent', () async {
      // game-1 already has user-001 joined in the seed data.
      final state = await repo.joinGame(session: member, gameId: 'game-1');
      final myRows = state.gamePlayers
          .where((p) => p.gameId == 'game-1' && p.userId == member.userId);
      expect(myRows, hasLength(1));
      expect(myRows.first.status, PlayerStatus.joined);
    });

    test('accepting a pending invite joins the game', () async {
      // Seed: user-001 has a pending invite to game-2.
      final state = await repo.respondGameInvite(
          session: member, gameId: 'game-2', accept: true);
      expect(state.playerStatusFor('game-2', member.userId),
          PlayerStatus.joined);
    });

    test('declining a pending invite marks it declined', () async {
      final state = await repo.respondGameInvite(
          session: member, gameId: 'game-2', accept: false);
      expect(state.playerStatusFor('game-2', member.userId),
          PlayerStatus.declined);
    });

    test('responding without a pending invite fails', () {
      // user-001 has no invite to game-1 (already joined).
      expect(
        () => repo.respondGameInvite(
            session: member, gameId: 'game-1', accept: true),
        throwsA(isA<AppFailure>()),
      );
    });

    test('inviteToGame records an invite and notifies the invitee', () async {
      final state = await repo.inviteToGame(
        session: member,
        gameId: 'game-1',
        userIds: const ['user-003'],
      );

      expect(state.playerStatusFor('game-1', 'user-003'), PlayerStatus.invited);
      expect(
        state.notifications.any((n) =>
            n.userId == 'user-003' && n.type == NotificationType.game),
        isTrue,
      );
    });
  });

  group('groups', () {
    test('createGroup adds the group and an owner membership', () async {
      final state = await repo.createGroup(
        session: member,
        name: 'Morning Runners',
        description: 'Dawn 5k club',
        department: 'All',
        isPublic: true,
      );

      final group = state.groups.firstWhere((g) => g.name == 'Morning Runners');
      expect(group.createdBy, member.userId);
      expect(
        state.groupMembers.any((m) =>
            m.groupId == group.id &&
            m.userId == member.userId &&
            m.role == 'owner'),
        isTrue,
      );
    });

    test('createGroup rejects a blank name', () {
      expect(
        () => repo.createGroup(
          session: member,
          name: '   ',
          description: '',
          department: '',
          isPublic: true,
        ),
        throwsA(isA<AppFailure>()),
      );
    });

    test('join then leave a group updates membership', () async {
      // Priya is not a member of group-1 in the seed.
      final joined = await repo.joinGroup(session: priya, groupId: 'group-1');
      expect(
        joined.groupMembers
            .any((m) => m.groupId == 'group-1' && m.userId == priya.userId),
        isTrue,
      );

      final left = await repo.leaveGroup(session: priya, groupId: 'group-1');
      expect(
        left.groupMembers
            .any((m) => m.groupId == 'group-1' && m.userId == priya.userId),
        isFalse,
      );
    });
  });

  group('friends', () {
    test('cannot send a friend request to yourself', () {
      expect(
        () => repo.sendFriendRequest(
            session: member, addresseeId: member.userId),
        throwsA(isA<AppFailure>()),
      );
    });

    test('cannot duplicate an existing connection', () {
      // Seed: user-001 <-> user-002 is already accepted.
      expect(
        () => repo.sendFriendRequest(session: member, addresseeId: 'user-002'),
        throwsA(isA<AppFailure>()),
      );
    });

    test('sending a request creates a pending row and notifies addressee',
        () async {
      // user-002 and user-003 have no connection in the seed.
      final state =
          await repo.sendFriendRequest(session: priya, addresseeId: 'user-003');

      final pending = state.friendships.where((f) =>
          f.requesterId == priya.userId &&
          f.addresseeId == 'user-003' &&
          f.status == FriendshipStatus.pending);
      expect(pending, hasLength(1));
      expect(
        state.notifications.any((n) => n.userId == 'user-003'),
        isTrue,
      );
    });

    test('accepting an incoming request marks it accepted', () async {
      // Seed: friend-2 is user-003 -> user-001 pending.
      final state = await repo.respondFriendRequest(
          session: member, friendshipId: 'friend-2', accept: true);

      expect(
        state.friendships.firstWhere((f) => f.id == 'friend-2').status,
        FriendshipStatus.accepted,
      );
      expect(state.friendIdsOf(member.userId), contains('user-003'));
    });

    test('declining an incoming request marks it declined', () async {
      final state = await repo.respondFriendRequest(
          session: member, friendshipId: 'friend-2', accept: false);

      expect(
        state.friendships.firstWhere((f) => f.id == 'friend-2').status,
        FriendshipStatus.declined,
      );
    });

    test('responding to a request not addressed to you fails', () {
      // friend-3 is user-001 -> user-004 (current user is the requester).
      expect(
        () => repo.respondFriendRequest(
            session: member, friendshipId: 'friend-3', accept: true),
        throwsA(isA<AppFailure>()),
      );
    });

    test('removeFriend drops the friendship row', () async {
      final state =
          await repo.removeFriend(session: member, friendshipId: 'friend-1');
      expect(state.friendships.any((f) => f.id == 'friend-1'), isFalse);
    });
  });

  group('notifications', () {
    test('markNotificationRead flips a single notification', () async {
      final state = await repo.markNotificationRead(
          session: member, notificationId: 'notif-1');
      expect(
        state.notifications.firstWhere((n) => n.id == 'notif-1').isRead,
        isTrue,
      );
    });

    test('markAllNotificationsRead clears the unread count', () async {
      final state = await repo.markAllNotificationsRead(session: member);
      expect(state.unreadNotificationCount(member.userId), 0);
    });

    test('requestAccountDeletion logs a system notification', () async {
      final before = (await repo.bootstrap(session: member)).notifications.length;
      final state = await repo.requestAccountDeletion(
          session: member, reason: 'Leaving the org');

      expect(state.notifications.length, before + 1);
      expect(state.notifications.first.type, NotificationType.system);
      expect(state.message, 'Deletion request submitted.');
    });
  });

  group('shared bookings', () {
    test('adding participants notifies them and records going status',
        () async {
      // booking-1 is owned by user-001; add user-003 as a participant.
      final state = await repo.addBookingParticipants(
        session: member,
        bookingId: 'booking-1',
        userIds: const ['user-003'],
      );

      expect(
        state.participantsOf('booking-1').any((p) =>
            p.userId == 'user-003' && p.status == ParticipantStatus.going),
        isTrue,
      );
      expect(
        state.notifications.any((n) =>
            n.userId == 'user-003' && n.type == NotificationType.booking),
        isTrue,
      );
    });

    test('the booking owner is never added as a participant', () async {
      final state = await repo.addBookingParticipants(
        session: member,
        bookingId: 'booking-1',
        userIds: [member.userId],
      );

      expect(
        state.participantsOf('booking-1').any((p) => p.userId == member.userId),
        isFalse,
      );
    });

    test('leaveSharedBooking removes the participant row', () async {
      // Seed: user-001 is a participant on booking-2 (owned by user-002).
      final state =
          await repo.leaveSharedBooking(session: member, bookingId: 'booking-2');
      expect(
        state.participantsOf('booking-2').any((p) => p.userId == member.userId),
        isFalse,
      );
    });
  });
}
