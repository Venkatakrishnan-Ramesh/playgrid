import 'playgrid_models.dart';

class PlayGridMockData {
  static const String currentUserId = 'user-001';
  static const String adminUserId = 'user-admin';

  /// Test accounts that the local repository will accept on the sign-in
  /// screen. The admin account routes the user to the admin tab; the others
  /// are regular members.
  ///
  /// Every account uses the password `password` for local development.
  static const List<({String email, String userId, UserRole role, String name})>
      knownAccounts = <({
    String email,
    String userId,
    UserRole role,
    String name
  })>[
    (
      email: 'admin@playgrid.club',
      userId: adminUserId,
      role: UserRole.admin,
      name: 'Court Admin',
    ),
    (
      email: 'arjun@acme.com',
      userId: currentUserId,
      role: UserRole.member,
      name: 'Arjun Rao',
    ),
    (
      email: 'priya@acme.com',
      userId: 'user-002',
      role: UserRole.member,
      name: 'Priya Nair',
    ),
    (
      email: 'kevin@acme.com',
      userId: 'user-003',
      role: UserRole.member,
      name: 'Kevin Thomas',
    ),
  ];

  static const PlayGridSession guestSession = PlayGridSession.guest();

  static const PlayGridSession memberSession = PlayGridSession(
    userId: currentUserId,
    email: 'arjun@acme.com',
    isAuthenticated: true,
    profileComplete: true,
    role: UserRole.member,
  );

  static final AppUserProfile memberProfile = AppUserProfile(
    id: currentUserId,
    name: 'Arjun Rao',
    email: 'arjun@acme.com',
    department: 'Engineering',
    avatarUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
    role: UserRole.member,
    skills: <SportPreference>[
      const SportPreference(
          sportId: 'sport-badminton', skillLevel: SkillLevel.advanced),
      const SportPreference(
          sportId: 'sport-cricket', skillLevel: SkillLevel.intermediate),
    ],
    createdAt: DateTime(2026, 1, 3),
    updatedAt: DateTime(2026, 3, 9),
  );

  static final AppUserProfile adminProfile = AppUserProfile(
    id: adminUserId,
    name: 'Court Admin',
    email: 'admin@playgrid.club',
    department: 'Operations',
    avatarUrl:
        'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=400',
    role: UserRole.admin,
    skills: const <SportPreference>[],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  /// Directory of members referenced by bookings, games, and groups so the UI
  /// can show real names in rosters instead of opaque user ids.
  static final List<AppUserProfile> members = <AppUserProfile>[
    adminProfile,
    memberProfile,
    AppUserProfile(
      id: 'user-002',
      name: 'Priya Nair',
      email: 'priya@acme.com',
      department: 'Design',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      role: UserRole.member,
      skills: const <SportPreference>[],
      createdAt: DateTime(2026, 1, 10),
      updatedAt: DateTime(2026, 3, 1),
    ),
    AppUserProfile(
      id: 'user-003',
      name: 'Kevin Thomas',
      email: 'kevin@acme.com',
      department: 'Sales',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      role: UserRole.member,
      skills: const <SportPreference>[],
      createdAt: DateTime(2026, 1, 15),
      updatedAt: DateTime(2026, 3, 4),
    ),
    AppUserProfile(
      id: 'user-004',
      name: 'Sara Iyer',
      email: 'sara@acme.com',
      department: 'Engineering',
      avatarUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
      role: UserRole.member,
      skills: const <SportPreference>[],
      createdAt: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 3, 6),
    ),
  ];

  /// Sport that the request/approve flow currently focuses on.
  static const String tennisSportId = 'sport-tennis';

  /// Default tennis venue used by the slot manager when seeding from scratch.
  static const String tennisVenueId = 'venue-tennis';

  static const List<Sport> sports = <Sport>[
    Sport(
        id: tennisSportId,
        name: 'Tennis',
        icon: 'sports_tennis',
        isActive: true,
        sortOrder: 0),
    Sport(
        id: 'sport-badminton',
        name: 'Badminton',
        icon: 'shuttlecock',
        isActive: true,
        sortOrder: 1),
    Sport(
        id: 'sport-cricket',
        name: 'Cricket',
        icon: 'sports_cricket',
        isActive: true,
        sortOrder: 2),
    Sport(
        id: 'sport-football',
        name: 'Football',
        icon: 'sports_soccer',
        isActive: true,
        sortOrder: 3),
    Sport(
        id: 'sport-basketball',
        name: 'Basketball',
        icon: 'sports_basketball',
        isActive: true,
        sortOrder: 4),
    Sport(
        id: 'sport-running',
        name: 'Running',
        icon: 'directions_run',
        isActive: true,
        sortOrder: 5),
  ];

  static const List<Venue> venues = <Venue>[
    Venue(
      id: tennisVenueId,
      name: 'PlayGrid Tennis Court',
      location: 'Koramangala, Bengaluru',
      description:
          'Clay-style tennis court with floodlights — booked via admin '
          'approval for member-friendly pricing.',
      surfaceType: 'Clay',
      capacity: 4,
      imageUrl:
          'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?w=900',
      isActive: true,
    ),
    Venue(
      id: 'venue-alpha',
      name: 'Alpha Sports Arena',
      location: 'Indiranagar, Bengaluru',
      description:
          'Indoor courts, bright lighting, and flexible evening slots.',
      surfaceType: 'Synthetic',
      capacity: 40,
      imageUrl:
          'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=900',
      isActive: true,
    ),
    Venue(
      id: 'venue-ridge',
      name: 'Ridge Turf Park',
      location: 'Whitefield, Bengaluru',
      description: '5-a-side turf with floodlights and spectator stands.',
      surfaceType: 'Turf',
      capacity: 24,
      imageUrl:
          'https://images.unsplash.com/photo-1486286701208-1d58e9338013?w=900',
      isActive: true,
    ),
    Venue(
      id: 'venue-lane',
      name: 'Lane Courts',
      location: 'HSR Layout, Bengaluru',
      description: 'Premium badminton courts and a lobby for meetups.',
      surfaceType: 'Wood',
      capacity: 32,
      imageUrl:
          'https://images.unsplash.com/photo-1526232761682-d26e031d67b8?w=900',
      isActive: true,
    ),
  ];

  static final List<VenueSlot> venueSlots = <VenueSlot>[
    VenueSlot(
      id: 'slot-1',
      venueId: 'venue-alpha',
      startAt: DateTime(2026, 5, 20, 18, 0),
      endAt: DateTime(2026, 5, 20, 19, 0),
      isBlocked: false,
      isAvailable: true,
      label: '6:00 PM - 7:00 PM',
    ),
    VenueSlot(
      id: 'slot-2',
      venueId: 'venue-alpha',
      startAt: DateTime(2026, 5, 20, 19, 0),
      endAt: DateTime(2026, 5, 20, 20, 0),
      isBlocked: false,
      isAvailable: true,
      label: '7:00 PM - 8:00 PM',
    ),
    VenueSlot(
      id: 'slot-3',
      venueId: 'venue-ridge',
      startAt: DateTime(2026, 5, 21, 18, 30),
      endAt: DateTime(2026, 5, 21, 19, 30),
      isBlocked: true,
      isAvailable: false,
      label: '6:30 PM - 7:30 PM',
    ),
  ];

  static final List<Booking> bookings = <Booking>[
    Booking(
      id: 'booking-1',
      userId: currentUserId,
      venueId: 'venue-alpha',
      sportId: 'sport-badminton',
      startAt: DateTime(2026, 5, 20, 18, 0),
      endAt: DateTime(2026, 5, 20, 19, 0),
      status: BookingStatus.confirmed,
      createdAt: DateTime(2026, 5, 18, 8, 0),
      notes: 'Team practice',
    ),
    Booking(
      id: 'booking-2',
      userId: 'user-002',
      venueId: 'venue-ridge',
      sportId: 'sport-football',
      startAt: DateTime(2026, 5, 21, 19, 0),
      endAt: DateTime(2026, 5, 21, 20, 0),
      status: BookingStatus.confirmed,
      createdAt: DateTime(2026, 5, 18, 8, 0),
      notes: 'Open game',
    ),
  ];

  static final List<Game> games = <Game>[
    Game(
      id: 'game-1',
      title: 'Badminton Corporate Clash',
      description: '4v4 ladder match with rolling substitutions.',
      sportId: 'sport-badminton',
      venueId: 'venue-lane',
      createdBy: currentUserId,
      startsAt: DateTime(2026, 5, 22, 18, 0),
      endsAt: DateTime(2026, 5, 22, 20, 0),
      maxPlayers: 8,
      status: GameStatus.open,
      waitlistEnabled: true,
    ),
    Game(
      id: 'game-2',
      title: 'Friday Turf Sprint',
      description: 'Fast-paced football game for mixed skill levels.',
      sportId: 'sport-football',
      venueId: 'venue-ridge',
      createdBy: 'user-003',
      startsAt: DateTime(2026, 5, 23, 18, 30),
      endsAt: DateTime(2026, 5, 23, 20, 0),
      maxPlayers: 12,
      status: GameStatus.open,
      waitlistEnabled: true,
    ),
  ];

  static final List<GamePlayer> gamePlayers = <GamePlayer>[
    GamePlayer(
      gameId: 'game-1',
      userId: currentUserId,
      status: PlayerStatus.joined,
      joinedAt: DateTime(2026, 5, 18),
    ),
    GamePlayer(
      gameId: 'game-1',
      userId: 'user-002',
      status: PlayerStatus.joined,
      joinedAt: DateTime(2026, 5, 18, 10),
    ),
    GamePlayer(
      gameId: 'game-1',
      userId: 'user-004',
      status: PlayerStatus.joined,
      joinedAt: DateTime(2026, 5, 18, 11),
    ),
    GamePlayer(
      gameId: 'game-2',
      userId: 'user-003',
      status: PlayerStatus.joined,
      joinedAt: DateTime(2026, 5, 19),
    ),
    // Current user has a pending invite to game-2.
    GamePlayer(
      gameId: 'game-2',
      userId: currentUserId,
      status: PlayerStatus.invited,
      joinedAt: DateTime(2026, 5, 19, 12),
    ),
  ];

  static final List<Friendship> friendships = <Friendship>[
    Friendship(
      id: 'friend-1',
      requesterId: currentUserId,
      addresseeId: 'user-002',
      status: FriendshipStatus.accepted,
      createdAt: DateTime(2026, 4, 1),
    ),
    // Incoming request waiting on the current user.
    Friendship(
      id: 'friend-2',
      requesterId: 'user-003',
      addresseeId: currentUserId,
      status: FriendshipStatus.pending,
      createdAt: DateTime(2026, 5, 20),
    ),
    // Outgoing request from the current user.
    Friendship(
      id: 'friend-3',
      requesterId: currentUserId,
      addresseeId: 'user-004',
      status: FriendshipStatus.pending,
      createdAt: DateTime(2026, 5, 22),
    ),
  ];

  static final List<BookingParticipant> bookingParticipants =
      <BookingParticipant>[
    // Priya is going to the current user's badminton booking.
    const BookingParticipant(
      bookingId: 'booking-1',
      userId: 'user-002',
      status: ParticipantStatus.going,
    ),
    // The current user was added to user-002's turf booking.
    const BookingParticipant(
      bookingId: 'booking-2',
      userId: currentUserId,
      status: ParticipantStatus.going,
    ),
  ];

  static const List<Group> groups = <Group>[
    Group(
      id: 'group-1',
      name: 'Engineering Badminton',
      description: 'Weekly ladder for the product and platform teams.',
      sportId: 'sport-badminton',
      department: 'Engineering',
      isPublic: false,
      createdBy: currentUserId,
    ),
    Group(
      id: 'group-2',
      name: 'Open Turf Club',
      description: 'Open invites for football and futsal evenings.',
      sportId: 'sport-football',
      department: 'All',
      isPublic: true,
      createdBy: 'user-002',
    ),
  ];

  static final List<GroupMember> groupMembers = <GroupMember>[
    GroupMember(
      groupId: 'group-1',
      userId: currentUserId,
      role: 'member',
      joinedAt: DateTime(2026, 5, 2),
    ),
    GroupMember(
      groupId: 'group-2',
      userId: currentUserId,
      role: 'member',
      joinedAt: DateTime(2026, 5, 12),
    ),
  ];

  static final List<EventItem> events = <EventItem>[
    EventItem(
      id: 'event-1',
      title: 'Inter-Department Tournament',
      description: 'Badminton and football finals this quarter.',
      entityType: 'tournament',
      entityId: 'tournament-2026-q2',
      startAt: DateTime(2026, 5, 29, 18, 0),
      endAt: DateTime(2026, 5, 29, 22, 0),
      location: 'Alpha Sports Arena',
    ),
  ];

  static final List<NotificationItem> notifications = <NotificationItem>[
    NotificationItem(
      id: 'notif-1',
      userId: currentUserId,
      title: 'Booking confirmed',
      body: 'Your 6:00 PM badminton slot is confirmed.',
      type: NotificationType.booking,
      isRead: false,
      createdAt: DateTime(2026, 5, 18, 8, 15),
    ),
    NotificationItem(
      id: 'notif-2',
      userId: currentUserId,
      title: 'New open game',
      body: 'Friday Turf Sprint now has 4 open slots.',
      type: NotificationType.game,
      isRead: true,
      createdAt: DateTime(2026, 5, 18, 9, 45),
    ),
  ];

  /// Generates seed court slots starting today + a few competing requests so
  /// the admin dashboard has something to act on out of the box.
  static List<CourtSlot> generateCourtSlots({DateTime? from}) {
    final DateTime base = from ?? DateTime.now();
    final DateTime today = DateTime(base.year, base.month, base.day);
    final List<CourtSlot> result = <CourtSlot>[];
    // Three days × four evening slots = 12 published tennis slots.
    const List<({int hour, int minute})> times = <({int hour, int minute})>[
      (hour: 17, minute: 0),
      (hour: 18, minute: 0),
      (hour: 19, minute: 0),
      (hour: 20, minute: 0),
    ];
    for (int dayOffset = 0; dayOffset < 3; dayOffset++) {
      final DateTime day = today.add(Duration(days: dayOffset));
      for (final ({int hour, int minute}) t in times) {
        final DateTime start =
            DateTime(day.year, day.month, day.day, t.hour, t.minute);
        final DateTime end = start.add(const Duration(hours: 1));
        result.add(CourtSlot(
          id: 'slot-tennis-${dayOffset}-${t.hour}',
          venueId: tennisVenueId,
          sportId: tennisSportId,
          startAt: start,
          endAt: end,
          capacity: 1,
          isOpen: true,
        ));
      }
    }
    return result;
  }

  static List<SlotRequest> generateSlotRequests({DateTime? from}) {
    final DateTime base = from ?? DateTime.now();
    final DateTime today = DateTime(base.year, base.month, base.day);
    final DateTime tomorrow = today.add(const Duration(days: 1));
    // Pre-existing competing requests on tomorrow's 6 PM slot, so the admin
    // dashboard shows a non-trivial decision out of the box.
    return <SlotRequest>[
      SlotRequest(
        id: 'req-seed-1',
        slotId: 'slot-tennis-1-18',
        userId: 'user-002',
        status: SlotRequestStatus.pending,
        notes: 'Singles practice with coach.',
        createdAt: tomorrow.subtract(const Duration(hours: 18)),
        decidedAt: null,
        decidedBy: null,
      ),
      SlotRequest(
        id: 'req-seed-2',
        slotId: 'slot-tennis-1-18',
        userId: 'user-003',
        status: SlotRequestStatus.pending,
        notes: 'Doubles with the sales team.',
        createdAt: tomorrow.subtract(const Duration(hours: 17)),
        decidedAt: null,
        decidedBy: null,
      ),
    ];
  }
}
