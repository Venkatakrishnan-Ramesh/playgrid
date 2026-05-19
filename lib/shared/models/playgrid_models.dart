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

enum PlayerStatus { joined, waitlisted, left }

enum NotificationType { booking, game, group, event, system }

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
  SkillLevel get skillLevel => skills.isEmpty ? SkillLevel.beginner : skills.first.skillLevel;

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

  bool get isActive => status == BookingStatus.confirmed || status == BookingStatus.pending;

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
      loading: loading ?? this.loading,
      message: message ?? this.message,
    );
  }

  List<Booking> upcomingBookingsFor(String userId) {
    return bookings
        .where((Booking booking) => booking.userId == userId && booking.isActive)
        .toList()
      ..sort((Booking a, Booking b) => a.startAt.compareTo(b.startAt));
  }

  List<Game> openGames() {
    return games.where((Game game) => game.status == GameStatus.open).toList();
  }
}
