import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/playgrid_models.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../auth/domain/playgrid_controller.dart';

class SportsScreen extends ConsumerWidget {
  const SportsScreen({super.key});

  @override
  Widget buildWithRef(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final PlayGridState state = controller.state;
    final selected = state.profile?.skills
            .map((SportPreference item) => item.sportId)
            .toSet() ??
        <String>{};

    return AppShell(
      title: 'Sports',
      body: ListView.separated(
        itemCount: state.sports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final Sport sport = state.sports[index];
          return FeatureCard(
            title: sport.name,
            subtitle: sport.icon,
            icon: Icons.sports,
            trailing: Chip(
                label: Text(
                    selected.contains(sport.id) ? 'Selected' : 'Available')),
          );
        },
      ),
    );
  }
}
