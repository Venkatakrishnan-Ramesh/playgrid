import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_screens.dart';
import '../../features/auth/domain/playgrid_controller.dart';
import '../../features/auth/presentation/auth_screens.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/games/presentation/game_screens.dart';
import '../../features/groups/presentation/group_screens.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/privacy_policy_screen.dart';
import '../../features/sports/presentation/sports_screen.dart';
import '../../features/venues/presentation/venue_screens.dart';
import 'route_paths.dart';

GoRouter createAppRouter(Ref ref) {
  final PlayGridController controller = ref.read(playGridControllerProvider);
  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: controller,
    redirect: (context, state) {
      final bool isAuthRoute = state.matchedLocation.startsWith('/auth');
      final bool isSetupRoute =
          state.matchedLocation == RoutePaths.profileSetup;
      final bool isAuthenticated = controller.state.session.isAuthenticated;
      final bool profileComplete = controller.state.session.profileComplete;

      if (!isAuthenticated && !isAuthRoute) {
        return RoutePaths.login;
      }

      if (isAuthenticated && !profileComplete && !isSetupRoute) {
        return RoutePaths.profileSetup;
      }

      if (isAuthenticated && isAuthRoute) {
        return RoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(
          path: RoutePaths.splash,
          name: 'splash',
          builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: RoutePaths.login,
          name: 'login',
          builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: RoutePaths.signup,
          name: 'signup',
          builder: (_, __) => const SignupScreen()),
      GoRoute(
          path: RoutePaths.forgotPassword,
          name: 'forgotPassword',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
          path: RoutePaths.profileSetup,
          name: 'profileSetup',
          builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(
          path: RoutePaths.home,
          name: 'home',
          builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: RoutePaths.profile,
          name: 'profile',
          builder: (_, __) => const ProfileScreen()),
      GoRoute(
          path: RoutePaths.sports,
          name: 'sports',
          builder: (_, __) => const SportsScreen()),
      GoRoute(
          path: RoutePaths.venues,
          name: 'venues',
          builder: (_, __) => const VenueListScreen()),
      GoRoute(
        path: RoutePaths.venueDetail,
        name: 'venueDetail',
        builder: (_, state) =>
            VenueDetailScreen(venueId: state.pathParameters['venueId'] ?? ''),
      ),
      GoRoute(
        path: RoutePaths.bookingCreate,
        name: 'bookingCreate',
        builder: (_, state) =>
            CreateBookingScreen(venueId: state.pathParameters['venueId'] ?? ''),
      ),
      GoRoute(
          path: RoutePaths.bookings,
          name: 'bookings',
          builder: (_, __) => const MyBookingsScreen()),
      GoRoute(
          path: RoutePaths.games,
          name: 'games',
          builder: (_, __) => const GamesScreen()),
      GoRoute(
          path: RoutePaths.gameCreate,
          name: 'createGame',
          builder: (_, __) => const CreateGameScreen()),
      GoRoute(
        path: RoutePaths.gameDetail,
        name: 'gameDetail',
        builder: (_, state) =>
            GameDetailScreen(gameId: state.pathParameters['gameId'] ?? ''),
      ),
      GoRoute(
          path: RoutePaths.groups,
          name: 'groups',
          builder: (_, __) => const GroupsScreen()),
      GoRoute(
        path: RoutePaths.groupDetail,
        name: 'groupDetail',
        builder: (_, state) =>
            GroupDetailScreen(groupId: state.pathParameters['groupId'] ?? ''),
      ),
      GoRoute(
          path: RoutePaths.events,
          name: 'events',
          builder: (_, __) => const EventsScreen()),
      GoRoute(
          path: RoutePaths.notifications,
          name: 'notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: RoutePaths.admin,
          name: 'admin',
          builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(
          path: RoutePaths.adminVenues,
          name: 'adminVenues',
          builder: (_, __) => const ManageVenuesScreen()),
      GoRoute(
          path: RoutePaths.settings,
          name: 'settings',
          builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: RoutePaths.privacyPolicy,
          name: 'privacyPolicy',
          builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(
          path: RoutePaths.accountDeletion,
          name: 'accountDeletion',
          builder: (_, __) => const AccountDeletionScreen()),
    ],
  );
}
