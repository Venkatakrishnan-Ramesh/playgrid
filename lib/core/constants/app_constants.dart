import 'package:flutter/material.dart';

import '../router/route_paths.dart';

class DashboardCard {
  const DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

class AppConstants {
  const AppConstants._();

  static const indigo = Color(0xFF273CFF);
  static const electricBlue = Color(0xFF0DA0FF);
  static const limeAccent = Color(0xFFA5FF5F);
  static const orangeAccent = Color(0xFFFF9B42);
  static const surfaceTint = Color(0xFFF4F7FF);

  static const dashboardCards = <DashboardCard>[
    DashboardCard(
      title: 'Book a Slot',
      subtitle: 'Reserve courts and turf',
      icon: Icons.calendar_month_outlined,
      route: RoutePaths.venues,
    ),
    DashboardCard(
      title: 'Join a Game',
      subtitle: 'Open games and waitlists',
      icon: Icons.emoji_events_outlined,
      route: RoutePaths.games,
    ),
    DashboardCard(
      title: 'My Bookings',
      subtitle: 'Upcoming bookings',
      icon: Icons.event_available_outlined,
      route: RoutePaths.bookings,
    ),
    DashboardCard(
      title: 'Groups',
      subtitle: 'Department clubs',
      icon: Icons.groups_outlined,
      route: RoutePaths.groups,
    ),
    DashboardCard(
      title: 'Tournaments',
      subtitle: 'Club events',
      icon: Icons.local_fire_department_outlined,
      route: RoutePaths.events,
    ),
  ];
}
