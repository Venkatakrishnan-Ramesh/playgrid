import '../../../core/errors/app_failure.dart';
import '../../../shared/models/playgrid_mock_data.dart';
import '../../../shared/models/playgrid_models.dart';
import '../domain/playgrid_repository.dart';

class LocalPlayGridRepository implements PlayGridRepository {
  LocalPlayGridRepository()
      : _sports = List<Sport>.from(PlayGridMockData.sports),
        _venues = List<Venue>.from(PlayGridMockData.venues),
        _venueSlots = List<VenueSlot>.from(PlayGridMockData.venueSlots),
        _bookings = List<Booking>.from(PlayGridMockData.bookings),
        _games = List<Game>.from(PlayGridMockData.games),
        _gamePlayers = List<GamePlayer>.from(PlayGridMockData.gamePlayers),
        _groups = List<Group>.from(PlayGridMockData.groups),
        _groupMembers = List<GroupMember>.from(PlayGridMockData.groupMembers),
        _events = List<EventItem>.from(PlayGridMockData.events),
        _notifications =
            List<NotificationItem>.from(PlayGridMockData.notifications),
        _members = List<AppUserProfile>.from(PlayGridMockData.members),
        _friendships = List<Friendship>.from(PlayGridMockData.friendships),
        _bookingParticipants =
            List<BookingParticipant>.from(PlayGridMockData.bookingParticipants);

  final List<Sport> _sports;
  final List<Venue> _venues;
  final List<VenueSlot> _venueSlots;
  final List<Booking> _bookings;
  final List<Game> _games;
  final List<GamePlayer> _gamePlayers;
  final List<Group> _groups;
  final List<GroupMember> _groupMembers;
  final List<EventItem> _events;
  final List<NotificationItem> _notifications;
  final List<AppUserProfile> _members;
  final List<Friendship> _friendships;
  final List<BookingParticipant> _bookingParticipants;

  PlayGridState _stateFor(PlayGridSession session, {AppUserProfile? profile}) {
    return PlayGridState(
      session: session.copyWith(
          profileComplete: profile != null,
          role: profile?.role ?? session.role),
      profile: profile,
      sports: List<Sport>.unmodifiable(_sports),
      venues: List<Venue>.unmodifiable(_venues),
      bookings: List<Booking>.unmodifiable(_bookings),
      games: List<Game>.unmodifiable(_games),
      gamePlayers: List<GamePlayer>.unmodifiable(_gamePlayers),
      groups: List<Group>.unmodifiable(_groups),
      groupMembers: List<GroupMember>.unmodifiable(_groupMembers),
      events: List<EventItem>.unmodifiable(_events),
      notifications: List<NotificationItem>.unmodifiable(_notifications),
      venueSlots: List<VenueSlot>.unmodifiable(_venueSlots),
      members: List<AppUserProfile>.unmodifiable(_members),
      friendships: List<Friendship>.unmodifiable(_friendships),
      bookingParticipants:
          List<BookingParticipant>.unmodifiable(_bookingParticipants),
      loading: false,
      message: profile == null ? 'Ready to sign in.' : 'Loaded PlayGrid Club.',
    );
  }

  AppUserProfile? _profileFor(PlayGridSession session) {
    if (!session.isAuthenticated || !session.profileComplete) {
      return null;
    }
    return PlayGridMockData.memberProfile.copyWith(
      id: session.userId,
      email: session.email.isEmpty
          ? PlayGridMockData.memberProfile.email
          : session.email,
    );
  }

  @override
  Future<PlayGridState> bootstrap({required PlayGridSession session}) async {
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> saveProfile({
    required PlayGridSession session,
    required String name,
    required String department,
    String? avatarUrl,
    SkillLevel? skillLevel,
    List<SportPreference>? sportsPreferences,
  }) async {
    final profile = AppUserProfile(
      id: session.userId,
      name: name.trim().isEmpty ? 'PlayGrid Member' : name.trim(),
      email: session.email,
      department: department.trim(),
      avatarUrl: avatarUrl ?? '',
      role: session.role,
      skills: sportsPreferences ?? const <SportPreference>[],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _stateFor(session.copyWith(profileComplete: true), profile: profile);
  }

  @override
  Future<PlayGridState> toggleSportPreference({
    required PlayGridSession session,
    required String sportId,
    required bool selected,
    SkillLevel? skillLevel,
  }) async {
    final baseProfile = _profileFor(session) ??
        AppUserProfile(
          id: session.userId,
          name: 'PlayGrid Member',
          email: session.email,
          department: '',
          avatarUrl: '',
          role: session.role,
          skills: const <SportPreference>[],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    final List<SportPreference> preferences = baseProfile.skills
        .where((item) => item.sportId != sportId)
        .toList(growable: true);
    if (selected) {
      preferences.add(
        SportPreference(
          sportId: sportId,
          skillLevel: skillLevel ??
              (baseProfile.skills.isNotEmpty
                  ? baseProfile.skills.first.skillLevel
                  : SkillLevel.beginner),
        ),
      );
    }
    return _stateFor(
      session.copyWith(profileComplete: true),
      profile:
          baseProfile.copyWith(skills: preferences, updatedAt: DateTime.now()),
    );
  }

  @override
  Future<PlayGridState> createBooking({
    required PlayGridSession session,
    required String venueId,
    required String sportId,
    required DateTime startAt,
    required DateTime endAt,
    required String notes,
  }) async {
    final conflict = _bookings.any(
      (booking) =>
          booking.venueId == venueId &&
          booking.status == BookingStatus.confirmed &&
          booking.endAt.isAfter(startAt) &&
          booking.startAt.isBefore(endAt),
    );
    if (conflict) {
      throw const AppFailure(
          'That slot overlaps an existing confirmed booking.');
    }
    _bookings.add(
      Booking(
        id: 'booking-${DateTime.now().microsecondsSinceEpoch}',
        userId: session.userId,
        venueId: venueId,
        sportId: sportId,
        startAt: startAt,
        endAt: endAt,
        status: BookingStatus.confirmed,
        createdAt: DateTime.now(),
        notes: notes,
      ),
    );
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> cancelBooking({
    required PlayGridSession session,
    required String bookingId,
  }) async {
    final index = _bookings.indexWhere((item) => item.id == bookingId);
    if (index == -1) {
      throw const AppFailure('Booking not found.');
    }
    final booking = _bookings[index];
    if (booking.userId != session.userId) {
      throw const AppFailure('You can only cancel your own bookings.');
    }
    _bookings[index] = booking.copyWith(status: BookingStatus.cancelled);
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> restoreBooking({
    required PlayGridSession session,
    required String bookingId,
  }) async {
    final index = _bookings.indexWhere((item) => item.id == bookingId);
    if (index == -1) {
      throw const AppFailure('Booking not found.');
    }
    final booking = _bookings[index];
    if (booking.userId != session.userId) {
      throw const AppFailure('You can only restore your own bookings.');
    }
    _bookings[index] = booking.copyWith(status: BookingStatus.confirmed);
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> createGame({
    required PlayGridSession session,
    required String title,
    required String description,
    required String sportId,
    required String venueId,
    required DateTime startsAt,
    required DateTime endsAt,
    required int maxPlayers,
  }) async {
    _games.add(
      Game(
        id: 'game-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        description: description,
        sportId: sportId,
        venueId: venueId,
        createdBy: session.userId,
        startsAt: startsAt,
        endsAt: endsAt,
        maxPlayers: maxPlayers,
        status: GameStatus.open,
        waitlistEnabled: true,
      ),
    );
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> joinGame({
    required PlayGridSession session,
    required String gameId,
  }) async {
    final bool activeAlready = _gamePlayers.any((item) =>
        item.gameId == gameId &&
        item.userId == session.userId &&
        (item.status == PlayerStatus.joined ||
            item.status == PlayerStatus.waitlisted));
    if (activeAlready) {
      return _stateFor(session, profile: _profileFor(session));
    }
    final game = _games.firstWhere(
      (item) => item.id == gameId,
      orElse: () => throw const AppFailure('Game not found.'),
    );
    final int joinedCount = _gamePlayers
        .where((item) =>
            item.gameId == gameId && item.status == PlayerStatus.joined)
        .length;
    final bool isFull = joinedCount >= game.maxPlayers;
    if (isFull && !game.waitlistEnabled) {
      throw const AppFailure('This game is full.');
    }
    // Clear any stale invited/declined/left row before re-adding.
    _gamePlayers.removeWhere(
        (item) => item.gameId == gameId && item.userId == session.userId);
    _gamePlayers.add(
      GamePlayer(
        gameId: gameId,
        userId: session.userId,
        status: isFull ? PlayerStatus.waitlisted : PlayerStatus.joined,
        joinedAt: DateTime.now(),
      ),
    );
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> leaveGame({
    required PlayGridSession session,
    required String gameId,
  }) async {
    final bool wasJoined = _gamePlayers.any((item) =>
        item.gameId == gameId &&
        item.userId == session.userId &&
        item.status == PlayerStatus.joined);
    _gamePlayers.removeWhere(
        (item) => item.gameId == gameId && item.userId == session.userId);

    // Free seat: promote the earliest waitlisted player, if any.
    if (wasJoined) {
      _promoteFromWaitlist(gameId);
    }
    return _stateFor(session, profile: _profileFor(session));
  }

  void _promoteFromWaitlist(String gameId) {
    final game = _games.firstWhere(
      (item) => item.id == gameId,
      orElse: () => throw const AppFailure('Game not found.'),
    );
    final int joinedCount = _gamePlayers
        .where((item) =>
            item.gameId == gameId && item.status == PlayerStatus.joined)
        .length;
    if (joinedCount >= game.maxPlayers) {
      return;
    }
    final waitlisted = _gamePlayers
        .where((item) =>
            item.gameId == gameId && item.status == PlayerStatus.waitlisted)
        .toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    if (waitlisted.isEmpty) {
      return;
    }
    final GamePlayer next = waitlisted.first;
    final int index = _gamePlayers.indexWhere(
        (item) => item.gameId == gameId && item.userId == next.userId);
    if (index != -1) {
      _gamePlayers[index] = GamePlayer(
        gameId: next.gameId,
        userId: next.userId,
        status: PlayerStatus.joined,
        joinedAt: next.joinedAt,
      );
    }
  }

  @override
  Future<PlayGridState> createGroup({
    required PlayGridSession session,
    required String name,
    required String description,
    required String department,
    required bool isPublic,
  }) async {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const AppFailure('Group name is required.');
    }
    final String groupId = 'group-${DateTime.now().microsecondsSinceEpoch}';
    _groups.add(
      Group(
        id: groupId,
        name: trimmedName,
        description: description.trim(),
        sportId: '',
        department: department.trim(),
        isPublic: isPublic,
        createdBy: session.userId,
      ),
    );
    // The creator is automatically the group owner.
    _groupMembers.add(
      GroupMember(
        groupId: groupId,
        userId: session.userId,
        role: 'owner',
        joinedAt: DateTime.now(),
      ),
    );
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> joinGroup({
    required PlayGridSession session,
    required String groupId,
  }) async {
    final alreadyMember = _groupMembers.any(
        (item) => item.groupId == groupId && item.userId == session.userId);
    if (!alreadyMember) {
      _groupMembers.add(
        GroupMember(
          groupId: groupId,
          userId: session.userId,
          role: 'member',
          joinedAt: DateTime.now(),
        ),
      );
    }
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> leaveGroup({
    required PlayGridSession session,
    required String groupId,
  }) async {
    _groupMembers.removeWhere(
        (item) => item.groupId == groupId && item.userId == session.userId);
    return _stateFor(session, profile: _profileFor(session));
  }

  // ---------------------------------------------------------------------------
  // Game invites
  // ---------------------------------------------------------------------------

  @override
  Future<PlayGridState> inviteToGame({
    required PlayGridSession session,
    required String gameId,
    required List<String> userIds,
  }) async {
    final Game game = _games.firstWhere(
      (item) => item.id == gameId,
      orElse: () => throw const AppFailure('Game not found.'),
    );
    final String inviterName = _memberName(session.userId);
    for (final String userId in userIds) {
      final bool exists = _gamePlayers.any((item) =>
          item.gameId == gameId &&
          item.userId == userId &&
          item.status != PlayerStatus.declined &&
          item.status != PlayerStatus.left);
      if (exists) {
        continue;
      }
      _gamePlayers
        ..removeWhere((item) => item.gameId == gameId && item.userId == userId)
        ..add(GamePlayer(
          gameId: gameId,
          userId: userId,
          status: PlayerStatus.invited,
          joinedAt: DateTime.now(),
        ));
      _pushNotification(
        userId: userId,
        title: 'Game invite',
        body: '$inviterName invited you to "${game.title}".',
        type: NotificationType.game,
      );
    }
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> respondGameInvite({
    required PlayGridSession session,
    required String gameId,
    required bool accept,
  }) async {
    final int index = _gamePlayers.indexWhere((item) =>
        item.gameId == gameId &&
        item.userId == session.userId &&
        item.status == PlayerStatus.invited);
    if (index == -1) {
      throw const AppFailure('No pending invite for this game.');
    }
    if (!accept) {
      _gamePlayers[index] = GamePlayer(
        gameId: gameId,
        userId: session.userId,
        status: PlayerStatus.declined,
        joinedAt: _gamePlayers[index].joinedAt,
      );
      return _stateFor(session, profile: _profileFor(session));
    }
    final Game game = _games.firstWhere(
      (item) => item.id == gameId,
      orElse: () => throw const AppFailure('Game not found.'),
    );
    final int joinedCount = _gamePlayers
        .where((item) =>
            item.gameId == gameId && item.status == PlayerStatus.joined)
        .length;
    final bool isFull = joinedCount >= game.maxPlayers;
    if (isFull && !game.waitlistEnabled) {
      throw const AppFailure('This game is full.');
    }
    _gamePlayers[index] = GamePlayer(
      gameId: gameId,
      userId: session.userId,
      status: isFull ? PlayerStatus.waitlisted : PlayerStatus.joined,
      joinedAt: DateTime.now(),
    );
    if (game.createdBy != session.userId) {
      _pushNotification(
        userId: game.createdBy,
        title: 'Invite accepted',
        body: '${_memberName(session.userId)} joined "${game.title}".',
        type: NotificationType.game,
      );
    }
    return _stateFor(session, profile: _profileFor(session));
  }

  // ---------------------------------------------------------------------------
  // Shared bookings
  // ---------------------------------------------------------------------------

  @override
  Future<PlayGridState> addBookingParticipants({
    required PlayGridSession session,
    required String bookingId,
    required List<String> userIds,
  }) async {
    final Booking booking = _bookings.firstWhere(
      (item) => item.id == bookingId,
      orElse: () => throw const AppFailure('Booking not found.'),
    );
    final Venue venue = _venues.firstWhere(
      (item) => item.id == booking.venueId,
      orElse: () => throw const AppFailure('Venue not found.'),
    );
    final String inviterName = _memberName(session.userId);
    for (final String userId in userIds) {
      if (userId == booking.userId) {
        continue;
      }
      final bool exists = _bookingParticipants
          .any((p) => p.bookingId == bookingId && p.userId == userId);
      if (exists) {
        continue;
      }
      _bookingParticipants.add(BookingParticipant(
        bookingId: bookingId,
        userId: userId,
        status: ParticipantStatus.going,
      ));
      _pushNotification(
        userId: userId,
        title: 'Added to a booking',
        body: '$inviterName added you to a booking at ${venue.name}.',
        type: NotificationType.booking,
      );
    }
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> leaveSharedBooking({
    required PlayGridSession session,
    required String bookingId,
  }) async {
    _bookingParticipants.removeWhere(
        (p) => p.bookingId == bookingId && p.userId == session.userId);
    return _stateFor(session, profile: _profileFor(session));
  }

  // ---------------------------------------------------------------------------
  // Friends
  // ---------------------------------------------------------------------------

  @override
  Future<PlayGridState> sendFriendRequest({
    required PlayGridSession session,
    required String addresseeId,
  }) async {
    if (addresseeId == session.userId) {
      throw const AppFailure('You cannot add yourself.');
    }
    final bool existing = _friendships.any((f) =>
        f.status != FriendshipStatus.declined &&
        ((f.requesterId == session.userId && f.addresseeId == addresseeId) ||
            (f.requesterId == addresseeId && f.addresseeId == session.userId)));
    if (existing) {
      throw const AppFailure('You already have a connection with this member.');
    }
    _friendships.add(Friendship(
      id: 'friend-${DateTime.now().microsecondsSinceEpoch}',
      requesterId: session.userId,
      addresseeId: addresseeId,
      status: FriendshipStatus.pending,
      createdAt: DateTime.now(),
    ));
    _pushNotification(
      userId: addresseeId,
      title: 'Friend request',
      body: '${_memberName(session.userId)} wants to connect.',
      type: NotificationType.system,
    );
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> respondFriendRequest({
    required PlayGridSession session,
    required String friendshipId,
    required bool accept,
  }) async {
    final int index = _friendships.indexWhere((f) =>
        f.id == friendshipId &&
        f.addresseeId == session.userId &&
        f.status == FriendshipStatus.pending);
    if (index == -1) {
      throw const AppFailure('No pending request found.');
    }
    final Friendship request = _friendships[index];
    _friendships[index] = Friendship(
      id: request.id,
      requesterId: request.requesterId,
      addresseeId: request.addresseeId,
      status: accept ? FriendshipStatus.accepted : FriendshipStatus.declined,
      createdAt: request.createdAt,
    );
    if (accept) {
      _pushNotification(
        userId: request.requesterId,
        title: 'Friend request accepted',
        body: '${_memberName(session.userId)} accepted your request.',
        type: NotificationType.system,
      );
    }
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> removeFriend({
    required PlayGridSession session,
    required String friendshipId,
  }) async {
    _friendships
        .removeWhere((f) => f.id == friendshipId && f.involves(session.userId));
    return _stateFor(session, profile: _profileFor(session));
  }

  String _memberName(String userId) {
    for (final AppUserProfile member in _members) {
      if (member.id == userId) {
        return member.name;
      }
    }
    return 'A member';
  }

  void _pushNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
  }) {
    _notifications.insert(
      0,
      NotificationItem(
        id: 'notification-${DateTime.now().microsecondsSinceEpoch}-$userId',
        userId: userId,
        title: title,
        body: body,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<PlayGridState> markNotificationRead({
    required PlayGridSession session,
    required String notificationId,
  }) async {
    final index =
        _notifications.indexWhere((item) => item.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> markAllNotificationsRead({
    required PlayGridSession session,
  }) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == session.userId &&
          !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> requestAccountDeletion({
    required PlayGridSession session,
    required String reason,
  }) async {
    _notifications.insert(
      0,
      NotificationItem(
        id: 'notification-${DateTime.now().microsecondsSinceEpoch}',
        userId: session.userId,
        title: 'Account deletion requested',
        body: reason.trim().isEmpty
            ? 'A deletion request was submitted.'
            : reason.trim(),
        type: NotificationType.system,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
    return _stateFor(session, profile: _profileFor(session))
        .copyWith(message: 'Deletion request submitted.');
  }
}
