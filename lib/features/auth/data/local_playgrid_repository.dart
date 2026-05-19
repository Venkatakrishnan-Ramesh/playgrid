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
        _notifications = List<NotificationItem>.from(PlayGridMockData.notifications);

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

  PlayGridState _stateFor(PlayGridSession session, {AppUserProfile? profile}) {
    return PlayGridState(
      session: session.copyWith(profileComplete: profile != null, role: profile?.role ?? session.role),
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
      email: session.email.isEmpty ? PlayGridMockData.memberProfile.email : session.email,
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
    final List<SportPreference> preferences =
        baseProfile.skills.where((item) => item.sportId != sportId).toList(growable: true);
    if (selected) {
      preferences.add(
        SportPreference(
          sportId: sportId,
          skillLevel: skillLevel ?? (baseProfile.skills.isNotEmpty ? baseProfile.skills.first.skillLevel : SkillLevel.beginner),
        ),
      );
    }
    return _stateFor(
      session.copyWith(profileComplete: true),
      profile: baseProfile.copyWith(skills: preferences, updatedAt: DateTime.now()),
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
      throw const AppFailure('That slot overlaps an existing confirmed booking.');
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
    final alreadyJoined = _gamePlayers.any((item) => item.gameId == gameId && item.userId == session.userId);
    if (!alreadyJoined) {
      _gamePlayers.add(
        GamePlayer(
          gameId: gameId,
          userId: session.userId,
          status: PlayerStatus.joined,
          joinedAt: DateTime.now(),
        ),
      );
    }
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> leaveGame({
    required PlayGridSession session,
    required String gameId,
  }) async {
    _gamePlayers.removeWhere((item) => item.gameId == gameId && item.userId == session.userId);
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> joinGroup({
    required PlayGridSession session,
    required String groupId,
  }) async {
    final alreadyMember =
        _groupMembers.any((item) => item.groupId == groupId && item.userId == session.userId);
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
    _groupMembers.removeWhere((item) => item.groupId == groupId && item.userId == session.userId);
    return _stateFor(session, profile: _profileFor(session));
  }

  @override
  Future<PlayGridState> markNotificationRead({
    required PlayGridSession session,
    required String notificationId,
  }) async {
    final index = _notifications.indexWhere((item) => item.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
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
        body: reason.trim().isEmpty ? 'A deletion request was submitted.' : reason.trim(),
        type: NotificationType.system,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
    return _stateFor(session, profile: _profileFor(session)).copyWith(message: 'Deletion request submitted.');
  }
}
