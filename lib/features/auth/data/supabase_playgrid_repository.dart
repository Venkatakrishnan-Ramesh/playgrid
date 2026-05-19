import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/models/playgrid_models.dart';
import '../domain/playgrid_repository.dart';
import 'supabase_mappers.dart';

class SupabasePlayGridRepository implements PlayGridRepository {
  SupabasePlayGridRepository({sb.SupabaseClient? client})
      : _client = client ?? sb.Supabase.instance.client;

  factory SupabasePlayGridRepository.fromConfig(AppConfig _) =>
      SupabasePlayGridRepository();

  final sb.SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // Bootstrap
  // ---------------------------------------------------------------------------

  @override
  Future<PlayGridState> bootstrap({required PlayGridSession session}) async {
    if (!session.isAuthenticated) {
      return PlayGridState(
        session: session,
        profile: null,
        sports: const <Sport>[],
        venues: const <Venue>[],
        bookings: const <Booking>[],
        games: const <Game>[],
        gamePlayers: const <GamePlayer>[],
        groups: const <Group>[],
        groupMembers: const <GroupMember>[],
        events: const <EventItem>[],
        notifications: const <NotificationItem>[],
        venueSlots: const <VenueSlot>[],
        loading: false,
        message: 'Ready to sign in.',
      );
    }

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _loadProfile(session.userId),
        _loadList('sports', orderBy: 'name'),
        _loadList('venues', orderBy: 'name'),
        _loadList('bookings', orderBy: 'slot_start'),
        _loadList('games', orderBy: 'start_time'),
        _loadList('game_players'),
        _loadList('groups', orderBy: 'name'),
        _loadList('group_members'),
        _loadList('events', orderBy: 'start_time'),
        _loadList('notifications', orderBy: 'created_at', descending: true),
      ]);

      final AppUserProfile? profile = results[0] as AppUserProfile?;
      final List<Sport> sports = (results[1] as List<Map<String, dynamic>>)
          .map(SupabaseMappers.sport)
          .toList(growable: false);
      final List<Venue> venues = (results[2] as List<Map<String, dynamic>>)
          .map(SupabaseMappers.venue)
          .toList(growable: false);
      final List<Booking> bookings = (results[3] as List<Map<String, dynamic>>)
          .map(SupabaseMappers.booking)
          .toList(growable: false);
      final List<Game> games = (results[4] as List<Map<String, dynamic>>)
          .map(SupabaseMappers.game)
          .toList(growable: false);
      final List<GamePlayer> gamePlayers =
          (results[5] as List<Map<String, dynamic>>)
              .map(SupabaseMappers.gamePlayer)
              .toList(growable: false);
      final List<Group> groups = (results[6] as List<Map<String, dynamic>>)
          .map(SupabaseMappers.group)
          .toList(growable: false);
      final List<GroupMember> groupMembers =
          (results[7] as List<Map<String, dynamic>>)
              .map(SupabaseMappers.groupMember)
              .toList(growable: false);
      final List<EventItem> events = (results[8] as List<Map<String, dynamic>>)
          .map(SupabaseMappers.event)
          .toList(growable: false);
      final List<NotificationItem> notifications =
          (results[9] as List<Map<String, dynamic>>)
              .map(SupabaseMappers.notification)
              .toList(growable: false);

      return PlayGridState(
        session: session.copyWith(
          profileComplete: profile != null &&
              profile.name.trim().isNotEmpty &&
              profile.department.trim().isNotEmpty,
          role: profile?.role ?? session.role,
        ),
        profile: profile,
        sports: sports,
        venues: venues,
        bookings: bookings,
        games: games,
        gamePlayers: gamePlayers,
        groups: groups,
        groupMembers: groupMembers,
        events: events,
        notifications: notifications,
        // Slot availability is derived from venues + bookings on the client
        // for now; there is no `venue_slots` table in the schema.
        venueSlots: const <VenueSlot>[],
        loading: false,
        message:
            profile == null ? 'Complete your profile to continue.' : 'Loaded.',
      );
    } on sb.PostgrestException catch (error) {
      throw AppFailure(error.message);
    }
  }

  Future<AppUserProfile?> _loadProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('*, user_sports(sport_id, skill_level)')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return SupabaseMappers.profile(row);
  }

  Future<List<Map<String, dynamic>>> _loadList(
    String table, {
    String? orderBy,
    bool descending = false,
  }) async {
    final base = _client.from(table).select();
    final List<dynamic> data = orderBy == null
        ? await base
        : await base.order(orderBy, ascending: !descending);
    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  @override
  Future<PlayGridState> saveProfile({
    required PlayGridSession session,
    required String name,
    required String department,
    String? avatarUrl,
    SkillLevel? skillLevel,
    List<SportPreference>? sportsPreferences,
  }) async {
    try {
      await _client.from('profiles').upsert(<String, dynamic>{
        'id': session.userId,
        'email': session.email,
        'name': name.trim().isEmpty ? 'PlayGrid Member' : name.trim(),
        'department': department.trim(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (skillLevel != null)
          'skill_level': SupabaseMappers.skillColumn(skillLevel),
      });

      if (sportsPreferences != null) {
        await _replaceUserSports(session.userId, sportsPreferences);
      }

      return bootstrap(session: session.copyWith(profileComplete: true));
    } on sb.PostgrestException catch (error) {
      throw AppFailure(error.message);
    }
  }

  @override
  Future<PlayGridState> toggleSportPreference({
    required PlayGridSession session,
    required String sportId,
    required bool selected,
    SkillLevel? skillLevel,
  }) async {
    try {
      if (selected) {
        await _client.from('user_sports').upsert(<String, dynamic>{
          'user_id': session.userId,
          'sport_id': sportId,
          'skill_level':
              SupabaseMappers.skillColumn(skillLevel ?? SkillLevel.beginner),
        });
      } else {
        await _client
            .from('user_sports')
            .delete()
            .eq('user_id', session.userId)
            .eq('sport_id', sportId);
      }
      return bootstrap(session: session);
    } on sb.PostgrestException catch (error) {
      throw AppFailure(error.message);
    }
  }

  Future<void> _replaceUserSports(
    String userId,
    List<SportPreference> preferences,
  ) async {
    await _client.from('user_sports').delete().eq('user_id', userId);
    if (preferences.isEmpty) {
      return;
    }
    final rows = preferences
        .map((pref) => <String, dynamic>{
              'user_id': userId,
              'sport_id': pref.sportId,
              'skill_level': SupabaseMappers.skillColumn(pref.skillLevel),
            })
        .toList(growable: false);
    await _client.from('user_sports').upsert(rows);
  }

  // ---------------------------------------------------------------------------
  // Bookings
  // ---------------------------------------------------------------------------

  @override
  Future<PlayGridState> createBooking({
    required PlayGridSession session,
    required String venueId,
    required String sportId,
    required DateTime startAt,
    required DateTime endAt,
    required String notes,
  }) async {
    try {
      await _client.rpc('create_booking_safe', params: <String, dynamic>{
        'p_venue_id': venueId,
        'p_sport_id': sportId,
        'p_slot_start': startAt.toUtc().toIso8601String(),
        'p_slot_end': endAt.toUtc().toIso8601String(),
        'p_notes': notes.isEmpty ? null : notes,
      });
      return bootstrap(session: session);
    } on sb.PostgrestException catch (error) {
      throw AppFailure(_bookingErrorMessage(error));
    }
  }

  @override
  Future<PlayGridState> cancelBooking({
    required PlayGridSession session,
    required String bookingId,
  }) async {
    try {
      await _client.rpc('cancel_booking', params: <String, dynamic>{
        'p_booking_id': bookingId,
        'p_reason': null,
      });
      return bootstrap(session: session);
    } on sb.PostgrestException catch (error) {
      throw AppFailure(error.message);
    }
  }

  String _bookingErrorMessage(sb.PostgrestException error) {
    return switch (error.message) {
      'auth_required' => 'Sign in to create a booking.',
      'invalid_slot_range' => 'End time must be after start time.',
      'venue_not_found_or_inactive' => 'That venue is no longer available.',
      'user_booking_conflict' => 'You already have a booking that overlaps.',
      'venue_booking_conflict' ||
      'booking_conflict_detected' =>
        'That slot is already booked.',
      _ => error.message,
    };
  }

  // ---------------------------------------------------------------------------
  // Games
  // ---------------------------------------------------------------------------

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
    try {
      await _client.from('games').insert(<String, dynamic>{
        'created_by': session.userId,
        'title': title,
        'description': description,
        'sport_id': sportId,
        'venue_id': venueId,
        'start_time': startsAt.toUtc().toIso8601String(),
        'end_time': endsAt.toUtc().toIso8601String(),
        'max_players': maxPlayers,
        'status': 'open',
      });
      return bootstrap(session: session);
    } on sb.PostgrestException catch (error) {
      throw AppFailure(error.message);
    }
  }

  @override
  Future<PlayGridState> joinGame({
    required PlayGridSession session,
    required String gameId,
  }) async {
    try {
      await _client.from('game_players').upsert(<String, dynamic>{
        'game_id': gameId,
        'user_id': session.userId,
        'status': 'joined',
      });
      return bootstrap(session: session);
    } on sb.PostgrestException catch (error) {
      throw AppFailure(error.message);
    }
  }

  @override
  Future<PlayGridState> leaveGame({
    required PlayGridSession session,
    required String gameId,
  }) async {
    try {
      await _client
          .from('game_players')
          .delete()
          .eq('game_id', gameId)
          .eq('user_id', session.userId);
      return bootstrap(session: session);
    } on sb.PostgrestException catch (error) {
      throw AppFailure(error.message);
    }
  }

  // ---------------------------------------------------------------------------
  // Groups
  // ---------------------------------------------------------------------------

  @override
  Future<PlayGridState> joinGroup({
    required PlayGridSession session,
    required String groupId,
  }) async {
    try {
      await _client.from('group_members').upsert(<String, dynamic>{
        'group_id': groupId,
        'user_id': session.userId,
        'status': 'member',
        'member_role': 'member',
      });
      return bootstrap(session: session);
    } on sb.PostgrestException catch (error) {
      throw AppFailure(error.message);
    }
  }

  @override
  Future<PlayGridState> leaveGroup({
    required PlayGridSession session,
    required String groupId,
  }) async {
    try {
      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', session.userId);
      return bootstrap(session: session);
    } on sb.PostgrestException catch (error) {
      throw AppFailure(error.message);
    }
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  @override
  Future<PlayGridState> markNotificationRead({
    required PlayGridSession session,
    required String notificationId,
  }) async {
    try {
      await _client
          .from('notifications')
          .update(<String, dynamic>{
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', session.userId);
      return bootstrap(session: session);
    } on sb.PostgrestException catch (error) {
      throw AppFailure(error.message);
    }
  }

  // ---------------------------------------------------------------------------
  // Account deletion request
  // ---------------------------------------------------------------------------

  @override
  Future<PlayGridState> requestAccountDeletion({
    required PlayGridSession session,
    required String reason,
  }) async {
    // The schema does not yet have an `account_deletion_requests` table.
    // Recording the request as a system notification keeps the same audit
    // trail the mock backend produced; replace with a dedicated table when
    // the support flow is finalised.
    try {
      await _client.from('notifications').insert(<String, dynamic>{
        'user_id': session.userId,
        'type': 'system',
        'title': 'Account deletion requested',
        'body': reason.trim().isEmpty
            ? 'A deletion request was submitted.'
            : reason.trim(),
      });
      final PlayGridState refreshed = await bootstrap(session: session);
      return refreshed.copyWith(message: 'Deletion request submitted.');
    } on sb.PostgrestException catch (error) {
      throw AppFailure(error.message);
    }
  }
}
