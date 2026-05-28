/// Safe id lookups that return a placeholder instead of throwing when a
/// referenced sport/venue is missing (e.g. after a refresh removes it).
extension SportListLookup on List<Sport> {
  Sport byId(String id) => firstWhere(
        (Sport sport) => sport.id == id,
        orElse: () => const Sport(
          id: '',
          name: 'Unknown sport',
          icon: '',
          isActive: false,
          sortOrder: 0,
        ),
      );
}

extension VenueListLookup on List<Venue> {
  Venue byId(String id) => firstWhere(
        (Venue venue) => venue.id == id,
        orElse: () => const Venue(
          id: '',
          name: 'Unknown venue',
          location: '',
          description: '',
          surfaceType: '',
          capacity: 0,
          imageUrl: '',
          isActive: false,
        ),
      );
}

enum UserRole { member, admin, superAdmin }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
        UserRole.member => 'Member',
        UserRole.admin => 'Admin',
        UserRole.superAdmin => 'Super Admin',
      };
}

enum SkillLevel { beginner, intermediate, advanced, elite }

extension SkillLevelLabel on SkillLevel {
  String get label => switch (this) {
        SkillLevel.beginner => 'Beginner',
        SkillLevel.intermediate => 'Intermediate',
        SkillLevel.advanced => 'Advanced',
        SkillLevel.elite => 'Elite',
      };
}

enum BookingStatus { pending, confirmed, cancelled, blocked }

extension BookingStatusLabel on BookingStatus {
  String get label => switch (this) {
        BookingStatus.pending => 'Pending',
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.blocked => 'Blocked',
      };
}

enum GameStatus { open, full, cancelled, completed }

extension GameStatusLabel on GameStatus {
  String get label => switch (this) {
        GameStatus.open => 'Open',
        GameStatus.full => 'Full',
        GameStatus.cancelled => 'Cancelled',
        GameStatus.completed => 'Completed',
      };
}

enum PlayerStatus { invited, joined, waitlisted, declined, left }

enum NotificationType { booking, game, group, event, system }

enum FriendshipStatus { pending, accepted, declined }

enum ParticipantStatus { invited, going, declined }

/// Lifecycle of a court-slot request made by a member.
///
/// `pending` → waiting on admin review.
/// `approved` → admin accepted this request (other competing requests for the
/// same slot are auto-rejected).
/// `rejected` → admin explicitly rejected, OR auto-rejected when a sibling
/// request for the same slot was approved.
/// `cancelled` → the requester withdrew before review.
enum SlotRequestStatus { pending, approved, rejected, cancelled }

extension SlotRequestStatusLabel on SlotRequestStatus {
  String get label => switch (this) {
        SlotRequestStatus.pending => 'Pending',
        SlotRequestStatus.approved => 'Approved',
        SlotRequestStatus.rejected => 'Rejected',
        SlotRequestStatus.cancelled => 'Cancelled',
      };
}

/// A court-slot template published by an admin (members request these).
class CourtSlot {
  const CourtSlot({
    required this.id,
    required this.venueId,
    required this.sportId,
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.isOpen,
  });

  final String id;
  final String venueId;
  final String sportId;
  final DateTime startAt;
  final DateTime endAt;

  /// Soft capacity: how many concurrent approvals the admin allows for this
  /// slot. Defaults to 1 (single-court / single-booking slot).
  final int capacity;

  /// Whether the slot is still open for requests (admins can close it without
  /// deleting it).
  final bool isOpen;

  String get label {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(startAt.hour)}:${two(startAt.minute)} - '
        '${two(endAt.hour)}:${two(endAt.minute)}';
  }

  CourtSlot copyWith({
    String? id,
    String? venueId,
    String? sportId,
    DateTime? startAt,
    DateTime? endAt,
    int? capacity,
    bool? isOpen,
  }) {
    return CourtSlot(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      sportId: sportId ?? this.sportId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      capacity: capacity ?? this.capacity,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

/// A member's request to claim a [CourtSlot].
class SlotRequest {
  const SlotRequest({
    required this.id,
    required this.slotId,
    required this.userId,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.decidedAt,
    required this.decidedBy,
  });

  final String id;
  final String slotId;
  final String userId;
  final SlotRequestStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final String? decidedBy;

  bool get isPending => status == SlotRequestStatus.pending;
  bool get isApproved => status == SlotRequestStatus.approved;

  SlotRequest copyWith({
    String? id,
    String? slotId,
    String? userId,
    SlotRequestStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? decidedAt,
    String? decidedBy,
  }) {
    return SlotRequest(
      id: id ?? this.id,
      slotId: slotId ?? this.slotId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      decidedAt: decidedAt ?? this.decidedAt,
      decidedBy: decidedBy ?? this.decidedBy,
    );
  }
}

class Friendship {
  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;
  final DateTime createdAt;

  /// The id of the other party relative to [userId].
  String otherUserId(String userId) =>
      requesterId == userId ? addresseeId : requesterId;

  bool involves(String userId) =>
      requesterId == userId || addresseeId == userId;
}

class BookingParticipant {
  const BookingParticipant({
    required this.bookingId,
    required this.userId,
    required this.status,
  });

  final String bookingId;
  final String userId;
  final ParticipantStatus status;
}

class SportPreference {
  const SportPreference({
    required this.sportId,
    required this.skillLevel,
  });

  final String sportId;
  final SkillLevel skillLevel;

  SportPreference copyWith({
    String? sportId,
    SkillLevel? skillLevel,
  }) {
    return SportPreference(
      sportId: sportId ?? this.sportId,
      skillLevel: skillLevel ?? this.skillLevel,
    );
  }
}

class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.avatarUrl,
    required this.role,
    required this.skills,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String department;
  final String avatarUrl;
  final UserRole role;
  final List<SportPreference> skills;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;

  AppUserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? avatarUrl,
    UserRole? role,
    List<SportPreference>? skills,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      skills: skills ?? this.skills,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension AppUserProfileCompat on AppUserProfile {
  SkillLevel get skillLevel =>
      skills.isEmpty ? SkillLevel.beginner : skills.first.skillLevel;

  List<SportPreference> get sportsPreferences => skills;
}

class Sport {
  const Sport({
    required this.id,
    required this.name,
    required this.icon,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String icon;
  final bool isActive;
  final int sortOrder;
}

class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.surfaceType,
    required this.capacity,
    required this.imageUrl,
    required this.isActive,
  });

  final String id;
  final String name;
  final String location;
  final String description;
  final String surfaceType;
  final int capacity;
  final String imageUrl;
  final bool isActive;
}

class VenueSlot {
  const VenueSlot({
    required this.id,
    required this.venueId,
    required this.startAt,
    required this.endAt,
    required this.isBlocked,
    required this.isAvailable,
    required this.label,
  });

  final String id;
  final String venueId;
  final DateTime startAt;
  final DateTime endAt;
  final bool isBlocked;
  final bool isAvailable;
  final String label;
}

class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.sportId,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.createdAt,
    required this.notes,
  });

  final String id;
  final String userId;
  final String venueId;
  final String sportId;
  final DateTime startAt;
  final DateTime endAt;
  final BookingStatus status;
  final DateTime createdAt;
  final String notes;

  bool get isActive =>
      status == BookingStatus.confirmed || status == BookingStatus.pending;

  Booking copyWith({
    String? id,
    String? userId,
    String? venueId,
    String? sportId,
    DateTime? startAt,
    DateTime? endAt,
    BookingStatus? status,
    DateTime? createdAt,
    String? notes,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      venueId: venueId ?? this.venueId,
      sportId: sportId ?? this.sportId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

class Game {
  const Game({
    required this.id,
    required this.title,
    required this.description,
    required this.sportId,
    required this.venueId,
    required this.createdBy,
    required this.startsAt,
    required this.endsAt,
    required this.maxPlayers,
    required this.status,
    required this.waitlistEnabled,
  });

  final String id;
  final String title;
  final String description;
  final String sportId;
  final String venueId;
  final String createdBy;
  final DateTime startsAt;
  final DateTime endsAt;
  final int maxPlayers;
  final GameStatus status;
  final bool waitlistEnabled;
}

class GamePlayer {
  const GamePlayer({
    required this.gameId,
    required this.userId,
    required this.status,
    required this.joinedAt,
  });

  final String gameId;
  final String userId;
  final PlayerStatus status;
  final DateTime joinedAt;
}

class Group {
  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.sportId,
    required this.department,
    required this.isPublic,
    required this.createdBy,
  });

  final String id;
  final String name;
  final String description;
  final String sportId;
  final String department;
  final bool isPublic;
  final String createdBy;
}

class GroupMember {
  const GroupMember({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  final String groupId;
  final String userId;
  final String role;
  final DateTime joinedAt;
}

class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.entityType,
    required this.entityId,
    required this.startAt,
    required this.endAt,
    required this.location,
  });

  final String id;
  final String title;
  final String description;
  final String entityType;
  final String entityId;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PlayGridSession {
  const PlayGridSession({
    required this.userId,
    required this.email,
    required this.isAuthenticated,
    required this.profileComplete,
    required this.role,
  });

  const PlayGridSession.guest()
      : userId = '',
        email = '',
        isAuthenticated = false,
        profileComplete = false,
        role = UserRole.member;

  final String userId;
  final String email;
  final bool isAuthenticated;
  final bool profileComplete;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;

  PlayGridSession copyWith({
    String? userId,
    String? email,
    bool? isAuthenticated,
    bool? profileComplete,
    UserRole? role,
  }) {
    return PlayGridSession(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      profileComplete: profileComplete ?? this.profileComplete,
      role: role ?? this.role,
    );
  }
}

class PlayGridState {
  const PlayGridState({
    required this.session,
    required this.profile,
    required this.sports,
    required this.venues,
    required this.bookings,
    required this.games,
    required this.gamePlayers,
    required this.groups,
    required this.groupMembers,
    required this.events,
    required this.notifications,
    required this.venueSlots,
    this.members = const <AppUserProfile>[],
    this.friendships = const <Friendship>[],
    this.bookingParticipants = const <BookingParticipant>[],
    this.courtSlots = const <CourtSlot>[],
    this.slotRequests = const <SlotRequest>[],
    required this.loading,
    required this.message,
  });

  final PlayGridSession session;
  final AppUserProfile? profile;
  final List<Sport> sports;
  final List<Venue> venues;
  final List<Booking> bookings;
  final List<Game> games;
  final List<GamePlayer> gamePlayers;
  final List<Group> groups;
  final List<GroupMember> groupMembers;
  final List<EventItem> events;
  final List<NotificationItem> notifications;
  final List<VenueSlot> venueSlots;

  /// Directory of known members, used to resolve display names for rosters.
  final List<AppUserProfile> members;
  final List<Friendship> friendships;
  final List<BookingParticipant> bookingParticipants;

  /// Admin-published bookable slots (currently tennis-only in the seed).
  final List<CourtSlot> courtSlots;

  /// All slot requests across all users. UI filters by user/admin as needed.
  final List<SlotRequest> slotRequests;
  final bool loading;
  final String message;

  const PlayGridState.initial()
      : session = const PlayGridSession.guest(),
        profile = null,
        sports = const <Sport>[],
        venues = const <Venue>[],
        bookings = const <Booking>[],
        games = const <Game>[],
        gamePlayers = const <GamePlayer>[],
        groups = const <Group>[],
        groupMembers = const <GroupMember>[],
        events = const <EventItem>[],
        notifications = const <NotificationItem>[],
        venueSlots = const <VenueSlot>[],
        members = const <AppUserProfile>[],
        friendships = const <Friendship>[],
        bookingParticipants = const <BookingParticipant>[],
        courtSlots = const <CourtSlot>[],
        slotRequests = const <SlotRequest>[],
        loading = false,
        message = '';

  PlayGridState copyWith({
    PlayGridSession? session,
    AppUserProfile? profile,
    List<Sport>? sports,
    List<Venue>? venues,
    List<Booking>? bookings,
    List<Game>? games,
    List<GamePlayer>? gamePlayers,
    List<Group>? groups,
    List<GroupMember>? groupMembers,
    List<EventItem>? events,
    List<NotificationItem>? notifications,
    List<VenueSlot>? venueSlots,
    List<AppUserProfile>? members,
    List<Friendship>? friendships,
    List<BookingParticipant>? bookingParticipants,
    List<CourtSlot>? courtSlots,
    List<SlotRequest>? slotRequests,
    bool? loading,
    String? message,
  }) {
    return PlayGridState(
      session: session ?? this.session,
      profile: profile ?? this.profile,
      sports: sports ?? this.sports,
      venues: venues ?? this.venues,
      bookings: bookings ?? this.bookings,
      games: games ?? this.games,
      gamePlayers: gamePlayers ?? this.gamePlayers,
      groups: groups ?? this.groups,
      groupMembers: groupMembers ?? this.groupMembers,
      events: events ?? this.events,
      notifications: notifications ?? this.notifications,
      venueSlots: venueSlots ?? this.venueSlots,
      members: members ?? this.members,
      friendships: friendships ?? this.friendships,
      bookingParticipants: bookingParticipants ?? this.bookingParticipants,
      courtSlots: courtSlots ?? this.courtSlots,
      slotRequests: slotRequests ?? this.slotRequests,
      loading: loading ?? this.loading,
      message: message ?? this.message,
    );
  }

  List<Booking> upcomingBookingsFor(String userId) {
    return bookings
        .where(
            (Booking booking) => booking.userId == userId && booking.isActive)
        .toList()
      ..sort((Booking a, Booking b) => a.startAt.compareTo(b.startAt));
  }

  List<Booking> cancelledBookingsFor(String userId) {
    return bookings
        .where((Booking booking) =>
            booking.userId == userId &&
            booking.status == BookingStatus.cancelled)
        .toList()
      ..sort((Booking a, Booking b) => b.startAt.compareTo(a.startAt));
  }

  List<Game> openGames() {
    return games.where((Game game) => game.status == GameStatus.open).toList();
  }

  /// Resolves a member by id, falling back to the signed-in profile.
  AppUserProfile? memberById(String userId) {
    for (final AppUserProfile member in members) {
      if (member.id == userId) {
        return member;
      }
    }
    if (profile != null && profile!.id == userId) {
      return profile;
    }
    return null;
  }

  /// Human-friendly name for a roster entry ("You" for the current user).
  String displayName(String userId) {
    if (userId == session.userId) {
      return 'You';
    }
    return memberById(userId)?.name ?? 'Member';
  }

  List<GamePlayer> joinedPlayers(String gameId) {
    return gamePlayers
        .where((GamePlayer player) =>
            player.gameId == gameId && player.status == PlayerStatus.joined)
        .toList()
      ..sort((GamePlayer a, GamePlayer b) => a.joinedAt.compareTo(b.joinedAt));
  }

  List<GamePlayer> waitlistedPlayers(String gameId) {
    return gamePlayers
        .where((GamePlayer player) =>
            player.gameId == gameId && player.status == PlayerStatus.waitlisted)
        .toList()
      ..sort((GamePlayer a, GamePlayer b) => a.joinedAt.compareTo(b.joinedAt));
  }

  PlayerStatus? playerStatusFor(String gameId, String userId) {
    for (final GamePlayer player in gamePlayers) {
      if (player.gameId == gameId && player.userId == userId) {
        return player.status;
      }
    }
    return null;
  }

  List<GroupMember> membersOf(String groupId) {
    return groupMembers
        .where((GroupMember member) => member.groupId == groupId)
        .toList()
      ..sort(
          (GroupMember a, GroupMember b) => a.joinedAt.compareTo(b.joinedAt));
  }

  int unreadNotificationCount(String userId) {
    return notifications
        .where((NotificationItem item) => item.userId == userId && !item.isRead)
        .length;
  }

  /// A player counts as "in" a game when joined or waitlisted (not merely
  /// invited or declined).
  bool isPlayerActive(String gameId, String userId) {
    final PlayerStatus? status = playerStatusFor(gameId, userId);
    return status == PlayerStatus.joined || status == PlayerStatus.waitlisted;
  }

  List<GamePlayer> invitedPlayers(String gameId) {
    return gamePlayers
        .where((GamePlayer player) =>
            player.gameId == gameId && player.status == PlayerStatus.invited)
        .toList();
  }

  // --- Friends -------------------------------------------------------------

  /// Accepted friend user ids for [userId].
  List<String> friendIdsOf(String userId) {
    return friendships
        .where((Friendship f) =>
            f.status == FriendshipStatus.accepted && f.involves(userId))
        .map((Friendship f) => f.otherUserId(userId))
        .toList(growable: false);
  }

  List<Friendship> incomingFriendRequests(String userId) {
    return friendships
        .where((Friendship f) =>
            f.status == FriendshipStatus.pending && f.addresseeId == userId)
        .toList(growable: false);
  }

  List<Friendship> outgoingFriendRequests(String userId) {
    return friendships
        .where((Friendship f) =>
            f.status == FriendshipStatus.pending && f.requesterId == userId)
        .toList(growable: false);
  }

  Friendship? friendshipBetween(String a, String b) {
    for (final Friendship f in friendships) {
      if (f.involves(a) && f.involves(b)) {
        return f;
      }
    }
    return null;
  }

  int pendingFriendRequestCount(String userId) =>
      incomingFriendRequests(userId).length;

  // --- Shared bookings -----------------------------------------------------

  List<BookingParticipant> participantsOf(String bookingId) {
    return bookingParticipants
        .where((BookingParticipant p) => p.bookingId == bookingId)
        .toList(growable: false);
  }

  /// Active bookings the user was invited to by someone else.
  List<Booking> sharedBookingsFor(String userId) {
    final Set<String> sharedIds = bookingParticipants
        .where((BookingParticipant p) =>
            p.userId == userId && p.status != ParticipantStatus.declined)
        .map((BookingParticipant p) => p.bookingId)
        .toSet();
    return bookings
        .where((Booking b) =>
            sharedIds.contains(b.id) && b.userId != userId && b.isActive)
        .toList()
      ..sort((Booking a, Booking b) => a.startAt.compareTo(b.startAt));
  }

  // --- Court slots & requests ----------------------------------------------

  /// All open slots for [sportId] that haven't already passed, sorted by
  /// start time.
  List<CourtSlot> openSlotsForSport(String sportId, {DateTime? now}) {
    final DateTime cutoff = now ?? DateTime.now();
    return courtSlots
        .where((CourtSlot slot) =>
            slot.sportId == sportId &&
            slot.isOpen &&
            slot.startAt.isAfter(cutoff))
        .toList()
      ..sort((CourtSlot a, CourtSlot b) => a.startAt.compareTo(b.startAt));
  }

  /// All slots for [sportId] on a specific calendar day (any status), sorted.
  List<CourtSlot> slotsForSportOn(String sportId, DateTime day) {
    return courtSlots
        .where((CourtSlot slot) =>
            slot.sportId == sportId && _sameLocalDay(slot.startAt, day))
        .toList()
      ..sort((CourtSlot a, CourtSlot b) => a.startAt.compareTo(b.startAt));
  }

  /// Calendar days (yyyy-mm-dd, local) on which any slot exists for [sportId].
  List<DateTime> slotDaysForSport(String sportId) {
    final Set<String> seen = <String>{};
    final List<DateTime> result = <DateTime>[];
    for (final CourtSlot slot in courtSlots) {
      if (slot.sportId != sportId) {
        continue;
      }
      final DateTime day = DateTime(
          slot.startAt.year, slot.startAt.month, slot.startAt.day);
      final String key = '${day.year}-${day.month}-${day.day}';
      if (seen.add(key)) {
        result.add(day);
      }
    }
    result.sort();
    return result;
  }

  List<SlotRequest> requestsForSlot(String slotId) {
    return slotRequests
        .where((SlotRequest r) => r.slotId == slotId)
        .toList()
      ..sort((SlotRequest a, SlotRequest b) =>
          a.createdAt.compareTo(b.createdAt));
  }

  List<SlotRequest> pendingRequestsForSlot(String slotId) {
    return requestsForSlot(slotId)
        .where((SlotRequest r) => r.isPending)
        .toList(growable: false);
  }

  List<SlotRequest> approvedRequestsForSlot(String slotId) {
    return requestsForSlot(slotId)
        .where((SlotRequest r) => r.isApproved)
        .toList(growable: false);
  }

  SlotRequest? requestBy(String slotId, String userId) {
    for (final SlotRequest r in slotRequests) {
      if (r.slotId == slotId && r.userId == userId) {
        return r;
      }
    }
    return null;
  }

  /// All requests made by [userId] still in flight or recently decided,
  /// newest first.
  List<SlotRequest> requestsByUser(String userId) {
    return slotRequests
        .where((SlotRequest r) => r.userId == userId)
        .toList()
      ..sort((SlotRequest a, SlotRequest b) =>
          b.createdAt.compareTo(a.createdAt));
  }

  /// Slot ids that still need admin attention (have ≥1 pending request and
  /// the slot is open), sorted by earliest start time.
  List<CourtSlot> slotsAwaitingAdmin() {
    final Set<String> pendingSlotIds = <String>{};
    for (final SlotRequest r in slotRequests) {
      if (r.isPending) {
        pendingSlotIds.add(r.slotId);
      }
    }
    return courtSlots
        .where((CourtSlot s) => pendingSlotIds.contains(s.id))
        .toList()
      ..sort((CourtSlot a, CourtSlot b) => a.startAt.compareTo(b.startAt));
  }

  bool _sameLocalDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
