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

  Future<PlayGridState> restoreBooking({
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

  Future<PlayGridState> inviteToGame({
    required PlayGridSession session,
    required String gameId,
    required List<String> userIds,
  });

  Future<PlayGridState> respondGameInvite({
    required PlayGridSession session,
    required String gameId,
    required bool accept,
  });

  Future<PlayGridState> joinGame({
    required PlayGridSession session,
    required String gameId,
  });

  Future<PlayGridState> leaveGame({
    required PlayGridSession session,
    required String gameId,
  });

  Future<PlayGridState> createGroup({
    required PlayGridSession session,
    required String name,
    required String description,
    required String department,
    required bool isPublic,
  });

  Future<PlayGridState> joinGroup({
    required PlayGridSession session,
    required String groupId,
  });

  Future<PlayGridState> leaveGroup({
    required PlayGridSession session,
    required String groupId,
  });

  // --- Shared bookings ------------------------------------------------------

  Future<PlayGridState> addBookingParticipants({
    required PlayGridSession session,
    required String bookingId,
    required List<String> userIds,
  });

  Future<PlayGridState> leaveSharedBooking({
    required PlayGridSession session,
    required String bookingId,
  });

  // --- Friends --------------------------------------------------------------

  Future<PlayGridState> sendFriendRequest({
    required PlayGridSession session,
    required String addresseeId,
  });

  Future<PlayGridState> respondFriendRequest({
    required PlayGridSession session,
    required String friendshipId,
    required bool accept,
  });

  Future<PlayGridState> removeFriend({
    required PlayGridSession session,
    required String friendshipId,
  });

  Future<PlayGridState> markNotificationRead({
    required PlayGridSession session,
    required String notificationId,
  });

  Future<PlayGridState> markAllNotificationsRead({
    required PlayGridSession session,
  });

  Future<PlayGridState> requestAccountDeletion({
    required PlayGridSession session,
    required String reason,
  });

  // --- Court slots & requests ----------------------------------------------

  /// Member: request a published [CourtSlot]. Multiple users can request the
  /// same slot — admins resolve via [approveSlotRequest].
  Future<PlayGridState> requestSlot({
    required PlayGridSession session,
    required String slotId,
    required String notes,
  });

  /// Member: cancel their own pending request.
  Future<PlayGridState> cancelSlotRequest({
    required PlayGridSession session,
    required String requestId,
  });

  /// Admin: approve a request. Auto-rejects every other pending request for
  /// the same slot once the slot's capacity is reached, and creates a
  /// `Booking` for the approved user. Notifies all affected members.
  Future<PlayGridState> approveSlotRequest({
    required PlayGridSession session,
    required String requestId,
  });

  /// Admin: reject a single pending request. Notifies the member.
  Future<PlayGridState> rejectSlotRequest({
    required PlayGridSession session,
    required String requestId,
    String? reason,
  });

  /// Admin: bulk-publish slots across a date range. Generates one [CourtSlot]
  /// per (date, time-of-day) pair. Skips combinations that already exist.
  Future<PlayGridState> addCourtSlots({
    required PlayGridSession session,
    required String venueId,
    required String sportId,
    required DateTime startDate,
    required DateTime endDate,
    required List<TimeOfDayValue> startTimes,
    required Duration duration,
    int capacity,
  });

  /// Admin: remove a slot. Pending requests are cancelled and requesters
  /// notified. Approved requests are also cancelled (the booking is removed)
  /// — admins use this for actual deletions and the UI confirms first.
  Future<PlayGridState> removeCourtSlot({
    required PlayGridSession session,
    required String slotId,
  });

  /// Emits whenever server-side data the [session] cares about changes
  /// (court slots, slot requests, bookings, notifications). Listeners
  /// typically respond by calling `bootstrap` to re-fetch.
  ///
  /// The local repository returns an empty stream — local state changes
  /// already propagate through the controller's existing notifyListeners().
  Stream<void> watchChanges({required PlayGridSession session});
}

/// Simple value type for an hour/minute pair that does not depend on Flutter
/// `TimeOfDay`, so it is safe to use across the domain + repository layer.
class TimeOfDayValue {
  const TimeOfDayValue({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is TimeOfDayValue && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}
