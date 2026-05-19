import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../auth/domain/playgrid_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final AppUserProfile? profile = state.profile;

    return AppShell(
      title: 'Profile',
      body: ListView(
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: profile?.avatarUrl.isNotEmpty == true
                        ? NetworkImage(profile!.avatarUrl)
                        : null,
                    child: profile == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(profile?.name ?? 'Guest user',
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(profile?.email ?? state.session.email),
                        Text(profile?.department ?? 'Department not set'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FeatureCard(
            title: 'Sports interests',
            subtitle: profile == null
                ? 'Set your favorite sports in profile setup'
                : profile.skills.map((SportPreference skill) {
                    final Sport? sport = state.sports
                            .where((Sport value) => value.id == skill.sportId)
                            .isEmpty
                        ? null
                        : state.sports.firstWhere(
                            (Sport value) => value.id == skill.sportId);
                    return sport == null
                        ? skill.skillLevel.label
                        : '${sport.name} · ${skill.skillLevel.label}';
                  }).join(' • '),
            icon: Icons.sports_tennis,
            onTap: () => context.go(RoutePaths.sports),
          ),
          const SizedBox(height: 16),
          FeatureCard(
            title: 'Complete profile setup',
            subtitle: 'Update sports, department, and role',
            icon: Icons.edit_outlined,
            onTap: () => context.go(RoutePaths.profileSetup),
          ),
        ],
      ),
    );
  }
}
