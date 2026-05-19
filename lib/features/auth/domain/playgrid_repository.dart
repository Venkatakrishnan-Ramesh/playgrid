import '../../../shared/models/playgrid_models.dart';

abstract class PlayGridRepository {
  Future<PlayGridState> bootstrap({required PlayGridSession session});

  Future<PlayGridState> saveProfile({
    required PlayGridSession session,
    required String name,
    required String department,
    String? avatarUrl,
    SkillLevel? skillLevel,
    List<SportPreference>? sportsPreferences,
  });

  Future<PlayGridState> toggleSportPreference({
    required PlayGridSession session,
    required String sportId,
    required bool selected,
    SkillLevel? skillLevel,
  });

  Future<PlayGridState> createBooking({
    required PlayGridSession session,
    required String venueId,
    required String sportId,
    required DateTime startAt,
    required DateTime endAt,
    required String notes,
  });

  Future<PlayGridState> cancelBooking({
    required PlayGridSession session,
    required String bookingId,
  });

  Future<PlayGridState> createGame({
    required PlayGridSession session,
    required String title,
    required String description,
    required String sportId,
    required String venueId,
    required DateTime startsAt,
    required DateTime endsAt,
    required int maxPlayers,
  });

  Future<PlayGridState> joinGame({
    required PlayGridSession session,
    required String gameId,
  });

  Future<PlayGridState> leaveGame({
    required PlayGridSession session,
    required String gameId,
  });

  Future<PlayGridState> joinGroup({
    required PlayGridSession session,
    required String groupId,
  });

  Future<PlayGridState> leaveGroup({
    required PlayGridSession session,
    required String groupId,
  });

  Future<PlayGridState> markNotificationRead({
    required PlayGridSession session,
    required String notificationId,
  });

  Future<PlayGridState> requestAccountDeletion({
    required PlayGridSession session,
    required String reason,
  });
}
