import 'package:flutter_test/flutter_test.dart';

import 'package:playgrid_mobile/features/auth/data/local_playgrid_repository.dart';
import 'package:playgrid_mobile/shared/models/playgrid_mock_data.dart';
import 'package:playgrid_mobile/shared/models/playgrid_models.dart';

/// Functional coverage for the derived query methods on [PlayGridState] that
/// the UI relies on for rosters, badges, friend lists, and shared bookings.
void main() {
  const PlayGridSession member = PlayGridMockData.memberSession; // user-001

  late PlayGridState state;

  setUp(() async {
    state = await LocalPlayGridRepository().bootstrap(session: member);
  });

  group('friend queries', () {
    test('friendIdsOf returns only accepted connections', () {
      // Seed: friend-1 (accepted), friend-2 (pending), friend-3 (pending).
      expect(state.friendIdsOf(member.userId), ['user-002']);
    });

    test('incomingFriendRequests returns requests addressed to the user', () {
      final incoming = state.incomingFriendRequests(member.userId);
      expect(incoming.map((f) => f.id), ['friend-2']);
    });

    test('outgoingFriendRequests returns requests sent by the user', () {
      final outgoing = state.outgoingFriendRequests(member.userId);
      expect(outgoing.map((f) => f.id), ['friend-3']);
    });

    test('pendingFriendRequestCount counts incoming pending only', () {
      expect(state.pendingFriendRequestCount(member.userId), 1);
    });

    test('friendshipBetween finds a relationship regardless of direction', () {
      expect(state.friendshipBetween('user-002', member.userId)?.id, 'friend-1');
      expect(state.friendshipBetween(member.userId, 'user-004')?.id, 'friend-3');
      expect(state.friendshipBetween('user-002', 'user-003'), isNull);
    });
  });

  group('game roster queries', () {
    test('joinedPlayers returns joined members sorted by join time', () {
      final joined = state.joinedPlayers('game-1');
      expect(joined.map((p) => p.userId),
          containsAll(<String>['user-001', 'user-002', 'user-004']));
      // Sorted ascending by joinedAt (user-001 joined first in the seed).
      expect(joined.first.userId, 'user-001');
    });

    test('isPlayerActive is true for joined, false for invited', () {
      expect(state.isPlayerActive('game-1', member.userId), isTrue);
      // user-001 only has a pending invite to game-2.
      expect(state.isPlayerActive('game-2', member.userId), isFalse);
    });

    test('playerStatusFor returns null when the user is not in the game', () {
      expect(state.playerStatusFor('game-1', 'user-999'), isNull);
    });

    test('invitedPlayers surfaces pending invites', () {
      expect(
        state.invitedPlayers('game-2').map((p) => p.userId),
        contains('user-001'),
      );
    });
  });

  group('booking queries', () {
    test('upcomingBookingsFor returns active bookings sorted by start', () {
      final upcoming = state.upcomingBookingsFor(member.userId);
      expect(upcoming.every((b) => b.isActive), isTrue);
      expect(upcoming.every((b) => b.userId == member.userId), isTrue);
      for (var i = 1; i < upcoming.length; i++) {
        expect(upcoming[i - 1].startAt.isAfter(upcoming[i].startAt), isFalse);
      }
    });

    test('sharedBookingsFor returns bookings owned by others', () {
      // Seed: user-001 is a participant on booking-2 (owned by user-002).
      final shared = state.sharedBookingsFor(member.userId);
      expect(shared.map((b) => b.id), contains('booking-2'));
      expect(shared.every((b) => b.userId != member.userId), isTrue);
    });

    test('participantsOf lists everyone added to a booking', () {
      expect(
        state.participantsOf('booking-1').map((p) => p.userId),
        contains('user-002'),
      );
    });
  });

  group('notification + roster helpers', () {
    test('unreadNotificationCount counts only this user\'s unread items', () {
      // Seed: notif-1 unread, notif-2 read → 1 unread for user-001.
      expect(state.unreadNotificationCount(member.userId), 1);
    });

    test('displayName resolves "You" for self and real names for others', () {
      expect(state.displayName(member.userId), 'You');
      expect(state.displayName('user-002'), 'Priya Nair');
    });

    test('membersOf returns a group roster sorted by join time', () {
      final roster = state.membersOf('group-1');
      expect(roster.map((m) => m.userId), contains('user-001'));
    });
  });
}
