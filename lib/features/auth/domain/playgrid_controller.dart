import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_dependencies.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/models/playgrid_models.dart';
import '../data/auth_service.dart';
import 'playgrid_repository.dart';

final Provider<PlayGridController> playGridControllerProvider =
    Provider<PlayGridController>((Ref ref) {
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
  List<Booking> get myBookings => _state.upcomingBookingsFor(_state.session.userId);
  List<Game> get openGames => _state.openGames();
  List<NotificationItem> get myNotifications =>
      _state.notifications.where((item) => item.userId == _state.session.userId).toList(growable: false);

  set _setState(PlayGridState value) {
    _state = value;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    _setState = _state.copyWith(loading: true, message: 'Preparing PlayGrid Club...');
    final PlayGridSession session = await _authService.currentSession();
    final PlayGridState data = await _repository.bootstrap(session: session);
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
      _setState = _state.copyWith(loading: true, message: 'Creating account...');
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

  Future<void> joinGame(String gameId) async {
    _setState = await _repository.joinGame(session: _state.session, gameId: gameId);
  }

  Future<void> leaveGame(String gameId) async {
    _setState = await _repository.leaveGame(session: _state.session, gameId: gameId);
  }

  Future<void> joinGroup(String groupId) async {
    _setState = await _repository.joinGroup(session: _state.session, groupId: groupId);
  }

  Future<void> leaveGroup(String groupId) async {
    _setState = await _repository.leaveGroup(session: _state.session, groupId: groupId);
  }

  Future<void> markNotificationRead(String notificationId) async {
    _setState = await _repository.markNotificationRead(
      session: _state.session,
      notificationId: notificationId,
    );
  }

  Future<void> requestAccountDeletion(String reason) async {
    _setState = await _repository.requestAccountDeletion(
      session: _state.session,
      reason: reason,
    );
  }
}
