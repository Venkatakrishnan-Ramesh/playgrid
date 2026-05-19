import 'playgrid_models.dart';

class PlayGridMockData {
  static const String currentUserId = 'user-001';

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

  static const List<Sport> sports = <Sport>[
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
}
