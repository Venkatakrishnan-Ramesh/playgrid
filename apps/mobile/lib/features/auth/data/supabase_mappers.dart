import '../../../shared/models/playgrid_models.dart';

/// JSON ↔ domain mappers for the Supabase implementation of
/// [PlayGridRepository]. Several DB columns don't have a 1:1 counterpart in
/// the current app models — those are mapped to the closest fit and the
/// loss is documented inline. Tightening the app models is tracked in the
/// launch checklist.
class SupabaseMappers {
  const SupabaseMappers._();

  // -------------------------------------------------------------------------
  // Enums
  // -------------------------------------------------------------------------

  static UserRole role(String? raw) => switch (raw) {
        'admin' => UserRole.admin,
        'super_admin' => UserRole.superAdmin,
        _ => UserRole.member,
      };

  static String roleColumn(UserRole role) => switch (role) {
        UserRole.member => 'member',
        UserRole.admin => 'admin',
        UserRole.superAdmin => 'super_admin',
      };

  static SkillLevel skill(String? raw) => switch (raw) {
        'intermediate' => SkillLevel.intermediate,
        'advanced' => SkillLevel.advanced,
        'pro' => SkillLevel.elite,
        _ => SkillLevel.beginner,
      };

  static String skillColumn(SkillLevel level) => switch (level) {
        SkillLevel.beginner => 'beginner',
        SkillLevel.intermediate => 'intermediate',
        SkillLevel.advanced => 'advanced',
        SkillLevel.elite => 'pro',
      };

  static BookingStatus bookingStatus(String? raw) => switch (raw) {
        'cancelled' => BookingStatus.cancelled,
        'blocked' => BookingStatus.blocked,
        // The DB has `completed` which we surface as `confirmed` for the
        // member views; admin-side reporting will eventually need its own
        // status.
        _ => BookingStatus.confirmed,
      };

  static GameStatus gameStatus(String? raw) => switch (raw) {
        'full' || 'in_progress' => GameStatus.full,
        'cancelled' => GameStatus.cancelled,
        'completed' => GameStatus.completed,
        _ => GameStatus.open,
      };

  static PlayerStatus playerStatus(String? raw) => switch (raw) {
        'invited' => PlayerStatus.invited,
        'waitlisted' => PlayerStatus.waitlisted,
        'declined' => PlayerStatus.declined,
        'left' => PlayerStatus.left,
        _ => PlayerStatus.joined,
      };

  static NotificationType notificationType(String? raw) => switch (raw) {
        'booking' => NotificationType.booking,
        'game' => NotificationType.game,
        'group' => NotificationType.group,
        'event' => NotificationType.event,
        _ => NotificationType.system,
      };

  // -------------------------------------------------------------------------
  // Rows → domain
  // -------------------------------------------------------------------------

  static AppUserProfile profile(Map<String, dynamic> row) {
    final List<SportPreference> skills = <SportPreference>[];
    final dynamic prefs = row['user_sports'];
    if (prefs is List) {
      for (final dynamic entry in prefs) {
        if (entry is Map<String, dynamic>) {
          skills.add(SportPreference(
            sportId: entry['sport_id'] as String? ?? '',
            skillLevel: skill(entry['skill_level'] as String?),
          ));
        }
      }
    }

    return AppUserProfile(
      id: row['id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      department: row['department'] as String? ?? '',
      avatarUrl: row['avatar_url'] as String? ?? '',
      role: role(row['role'] as String?),
      skills: skills,
      createdAt: _timestamp(row['created_at']),
      updatedAt: _timestamp(row['updated_at']),
    );
  }

  /// Lightweight profile used for the roster member directory (no sport
  /// preferences joined).
  static AppUserProfile member(Map<String, dynamic> row) => AppUserProfile(
        id: row['id'] as String? ?? '',
        name: row['name'] as String? ?? '',
        email: row['email'] as String? ?? '',
        department: row['department'] as String? ?? '',
        avatarUrl: row['avatar_url'] as String? ?? '',
        role: role(row['role'] as String?),
        skills: const <SportPreference>[],
        createdAt: _timestamp(row['created_at']),
        updatedAt: _timestamp(row['updated_at']),
      );

  static Sport sport(Map<String, dynamic> row) => Sport(
        id: row['id'] as String? ?? '',
        name: row['name'] as String? ?? '',
        icon: row['icon_name'] as String? ?? '',
        isActive: row['is_active'] as bool? ?? true,
        // The schema doesn't carry an explicit sort order yet; alphabetical
        // order is good enough until the column exists.
        sortOrder: 0,
      );

  static Venue venue(Map<String, dynamic> row) {
    final String address = row['address'] as String? ?? '';
    final String city = row['city'] as String? ?? '';
    final String location = <String>[address, city]
        .where((part) => part.trim().isNotEmpty)
        .join(', ');

    final dynamic amenities = row['amenities'];
    String surface = '';
    if (amenities is List && amenities.isNotEmpty) {
      surface = amenities.first.toString();
    }

    return Venue(
      id: row['id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      location: location,
      description: row['description'] as String? ?? '',
      surfaceType: surface,
      // Capacity / imageUrl don't exist in the schema yet — kept as defaults
      // so the existing list/detail UI still renders without crashing.
      capacity: 0,
      imageUrl: '',
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  static Booking booking(Map<String, dynamic> row) => Booking(
        id: row['id'] as String? ?? '',
        userId: row['user_id'] as String? ?? '',
        venueId: row['venue_id'] as String? ?? '',
        sportId: row['sport_id'] as String? ?? '',
        startAt: _timestamp(row['slot_start']),
        endAt: _timestamp(row['slot_end']),
        status: bookingStatus(row['status'] as String?),
        createdAt: _timestamp(row['created_at']),
        notes: row['notes'] as String? ?? '',
      );

  static Game game(Map<String, dynamic> row) => Game(
        id: row['id'] as String? ?? '',
        title: row['title'] as String? ?? '',
        description: row['description'] as String? ?? '',
        sportId: row['sport_id'] as String? ?? '',
        venueId: row['venue_id'] as String? ?? '',
        createdBy: row['created_by'] as String? ?? '',
        startsAt: _timestamp(row['start_time']),
        endsAt: _timestamp(row['end_time']),
        maxPlayers: (row['max_players'] as num?)?.toInt() ?? 0,
        status: gameStatus(row['status'] as String?),
        waitlistEnabled: row['waitlist_enabled'] as bool? ?? true,
      );

  static GamePlayer gamePlayer(Map<String, dynamic> row) => GamePlayer(
        gameId: row['game_id'] as String? ?? '',
        userId: row['user_id'] as String? ?? '',
        status: playerStatus(row['status'] as String?),
        joinedAt: _timestamp(row['joined_at']),
      );

  static Group group(Map<String, dynamic> row) => Group(
        id: row['id'] as String? ?? '',
        name: row['name'] as String? ?? '',
        description: row['description'] as String? ?? '',
        // The schema scopes groups by department, not by a single sport. The
        // app model still expects a sport id — leave it blank until the data
        // model is reworked.
        sportId: '',
        department: row['department_scope'] as String? ?? '',
        isPublic: (row['visibility'] as String?) == 'public',
        createdBy: row['created_by'] as String? ?? '',
      );

  static GroupMember groupMember(Map<String, dynamic> row) => GroupMember(
        groupId: row['group_id'] as String? ?? '',
        userId: row['user_id'] as String? ?? '',
        role: row['member_role'] as String? ?? 'member',
        joinedAt: _timestamp(row['joined_at']),
      );

  static EventItem event(Map<String, dynamic> row) {
    final String entityId = (row['group_id'] as String?) ??
        (row['sport_id'] as String?) ??
        (row['venue_id'] as String?) ??
        '';
    return EventItem(
      id: row['id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      entityType: row['event_kind'] as String? ?? 'other',
      entityId: entityId,
      startAt: _timestamp(row['start_time']),
      endAt: _timestamp(row['end_time']),
      // The schema doesn't denormalize venue address into events; resolve
      // client-side once an events screen needs the venue name.
      location: '',
    );
  }

  static NotificationItem notification(Map<String, dynamic> row) =>
      NotificationItem(
        id: row['id'] as String? ?? '',
        userId: row['user_id'] as String? ?? '',
        title: row['title'] as String? ?? '',
        body: row['body'] as String? ?? '',
        type: notificationType(row['type'] as String?),
        isRead: row['read_at'] != null,
        createdAt: _timestamp(row['created_at']),
      );

  static DateTime _timestamp(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toUtc() ?? DateTime.now().toUtc();
    }
    if (raw is DateTime) {
      return raw.toUtc();
    }
    return DateTime.now().toUtc();
  }
}
