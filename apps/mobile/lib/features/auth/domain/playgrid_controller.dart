import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_dependencies.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/models/playgrid_models.dart';
import '../data/auth_service.dart';
import 'playgrid_repository.dart';

/// Exposes the [PlayGridController] as a [ChangeNotifierProvider] so that every
/// `ref.watch` rebuilds when the controller calls `notifyListeners()`. A plain
/// `Provider` would hand out the same controller instance and never rebuild on
/// state changes, which is why created games/bookings only appeared after
/// navigating away and back.
final ChangeNotifierProvider<PlayGridController> playGridControllerProvider =
    ChangeNotifierProvider<PlayGridController>((Ref ref) {
  AppDependencies.initialize(AppConfig.fromEnvironment());
  return PlayGridController(
    authService: AppDependencies.authService,
    repository: AppDependencies.repository,
  );
});

class PlayGridController extends ChangeNotifier {
  PlayGridController({
    required AuthService authService,
    required PlayGridRepository repository,
  })  : _authService = authService,
        _repository = repository;

  final AuthService _authService;
  final PlayGridRepository _repository;
  PlayGridState _state = const PlayGridState.initial();

  PlayGridState get state => _state;
  AppUserProfile? get currentUser => _state.profile;
  List<Sport> get sports => _state.sports;
  List<Venue> get venues => _state.venues;
  List<Booking> get bookings => _state.bookings;
  List<Game> get games => _state.games;
  List<Group> get groups => _state.groups;
  List<EventItem> get events => _state.events;
  List<NotificationItem> get notifications => _state.notifications;
  List<VenueSlot> get venueSlots => _state.venueSlots;
  List<Booking> get myBookings =>
      _state.upcomingBookingsFor(_state.session.userId);
  List<Game> get openGames => _state.openGames();
  List<NotificationItem> get myNotifications => _state.notifications
      .where((item) => item.userId == _state.session.userId)
      .toList(growable: false);

  set _setState(PlayGridState value) {
    _state = value;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    _setState =
        _state.copyWith(loading: true, message: 'Preparing PlayGrid Club...');
    final PlayGridSession session = await _authService.currentSession();
    final PlayGridState data = await _repository.bootstrap(session: session);
    _setState = data.copyWith(loading: false);
  }

  /// Re-fetches everything for the current session (pull-to-refresh).
  Future<void> refresh() async {
    _setState = _state.copyWith(loading: true);
    final PlayGridState data =
        await _repository.bootstrap(session: _state.session);
    _setState = data.copyWith(loading: false);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setState = _state.copyWith(loading: true, message: 'Signing in...');
      final PlayGridSession session = await _authService.signIn(
        email: email,
        password: password,
      );
      _setState = await _repository.bootstrap(session: session);
    } on AppFailure catch (error) {
      _setState = _state.copyWith(message: error.message, loading: false);
      rethrow;
    } finally {
      _setState = _state.copyWith(loading: false);
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _setState =
          _state.copyWith(loading: true, message: 'Creating account...');
      final PlayGridSession session = await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );
      _setState = await _repository.bootstrap(session: session);
    } on AppFailure catch (error) {
      _setState = _state.copyWith(message: error.message, loading: false);
      rethrow;
    } finally {
      _setState = _state.copyWith(loading: false);
    }
  }

  Future<void> sendPasswordReset({required String email}) async {
    await _authService.sendPasswordReset(email: email);
    _setState = _state.copyWith(message: 'Password reset instructions sent.');
  }

  Future<void> signOut() async {
    await _authService.signOut();
    final PlayGridSession session = await _authService.currentSession();
    _setState = await _repository.bootstrap(session: session);
  }

  Future<void> saveProfile({
    required String name,
    required String department,
    String? avatarUrl,
    SkillLevel? skillLevel,
    List<SportPreference>? sportsPreferences,
  }) async {
    _setState = _state.copyWith(loading: true);
    final PlayGridState updated = await _repository.saveProfile(
      session: _state.session,
      name: name,
      department: department,
      avatarUrl: avatarUrl,
      skillLevel: skillLevel,
      sportsPreferences: sportsPreferences,
    );
    _setState = updated.copyWith(loading: false);
  }

  Future<void> toggleSportPreference({
    required String sportId,
    required bool selected,
    SkillLevel? skillLevel,
  }) async {
    final PlayGridState updated = await _repository.toggleSportPreference(
      session: _state.session,
      sportId: sportId,
      selected: selected,
      skillLevel: skillLevel,
    );
    _setState = updated;
  }

  Future<void> createBooking({
    required String venueId,
    required String sportId,
    required DateTime startAt,
    required DateTime endAt,
    required String notes,
  }) async {
    _setState = _state.copyWith(loading: true);
    final PlayGridState updated = await _repository.createBooking(
      session: _state.session,
      venueId: venueId,
      sportId: sportId,
      startAt: startAt,
      endAt: endAt,
      notes: notes,
    );
    _setState = updated.copyWith(loading: false);
  }

  Future<void> cancelBooking(String bookingId) async {
    _setState = _state.copyWith(loading: true);
    final PlayGridState updated = await _repository.cancelBooking(
      session: _state.session,
      bookingId: bookingId,
    );
    _setState = updated.copyWith(loading: false);
  }

  Future<void> restoreBooking(String bookingId) async {
    _setState = _state.copyWith(loading: true);
    final PlayGridState updated = await _repository.restoreBooking(
      session: _state.session,
      bookingId: bookingId,
    );
    _setState = updated.copyWith(loading: false);
  }

  Future<void> createGame({
    required String title,
    required String description,
    required String sportId,
    required String venueId,
    required DateTime startsAt,
    required DateTime endsAt,
    required int maxPlayers,
  }) async {
    final PlayGridState updated = await _repository.createGame(
      session: _state.session,
      title: title,
      description: description,
      sportId: sportId,
      venueId: venueId,
      startsAt: startsAt,
      endsAt: endsAt,
      maxPlayers: maxPlayers,
    );
    _setState = updated;
  }

  Future<void> inviteToGame(String gameId, List<String> userIds) async {
    _setState = await _repository.inviteToGame(
      session: _state.session,
      gameId: gameId,
      userIds: userIds,
    );
  }

  Future<void> respondGameInvite(String gameId, {required bool accept}) async {
    _setState = await _repository.respondGameInvite(
      session: _state.session,
      gameId: gameId,
      accept: accept,
    );
  }

  Future<void> joinGame(String gameId) async {
    _setState =
        await _repository.joinGame(session: _state.session, gameId: gameId);
  }

  Future<void> addBookingParticipants(
      String bookingId, List<String> userIds) async {
    _setState = await _repository.addBookingParticipants(
      session: _state.session,
      bookingId: bookingId,
      userIds: userIds,
    );
  }

  Future<void> leaveSharedBooking(String bookingId) async {
    _setState = await _repository.leaveSharedBooking(
      session: _state.session,
      bookingId: bookingId,
    );
  }

  Future<void> sendFriendRequest(String addresseeId) async {
    _setState = await _repository.sendFriendRequest(
      session: _state.session,
      addresseeId: addresseeId,
    );
  }

  Future<void> respondFriendRequest(String friendshipId,
      {required bool accept}) async {
    _setState = await _repository.respondFriendRequest(
      session: _state.session,
      friendshipId: friendshipId,
      accept: accept,
    );
  }

  Future<void> removeFriend(String friendshipId) async {
    _setState = await _repository.removeFriend(
      session: _state.session,
      friendshipId: friendshipId,
    );
  }

  Future<void> leaveGame(String gameId) async {
    _setState =
        await _repository.leaveGame(session: _state.session, gameId: gameId);
  }

  Future<void> createGroup({
    required String name,
    required String description,
    required String department,
    required bool isPublic,
  }) async {
    _setState = await _repository.createGroup(
      session: _state.session,
      name: name,
      description: description,
      department: department,
      isPublic: isPublic,
    );
  }

  Future<void> joinGroup(String groupId) async {
    _setState =
        await _repository.joinGroup(session: _state.session, groupId: groupId);
  }

  Future<void> leaveGroup(String groupId) async {
    _setState =
        await _repository.leaveGroup(session: _state.session, groupId: groupId);
  }

  Future<void> markNotificationRead(String notificationId) async {
    _setState = await _repository.markNotificationRead(
      session: _state.session,
      notificationId: notificationId,
    );
  }

  Future<void> markAllNotificationsRead() async {
    _setState = await _repository.markAllNotificationsRead(
      session: _state.session,
    );
  }

  Future<void> requestAccountDeletion(String reason) async {
    _setState = await _repository.requestAccountDeletion(
      session: _state.session,
      reason: reason,
    );
  }
}
