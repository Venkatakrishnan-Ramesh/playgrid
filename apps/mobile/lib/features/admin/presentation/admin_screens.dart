import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../auth/domain/playgrid_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final bool isAdmin = controller.state.session.isAdmin ||
        (controller.state.profile?.isAdmin ?? false);

    if (!isAdmin) {
      return const AppShell(
        title: 'Admin',
        body: Center(child: Text('Admin access required')),
      );
    }

    return AppShell(
      title: 'Admin dashboard',
      body: ListView(
        children: <Widget>[
          FeatureCard(
            title: 'Manage venues',
            subtitle: 'Add, edit, and review venue inventory',
            icon: Icons.storefront_outlined,
            onTap: () => context.go('/admin/venues'),
          ),
          const SizedBox(height: 12),
          const FeatureCard(
            title: 'Block slot placeholder',
            subtitle: 'Reserve maintenance windows and blackout periods',
            icon: Icons.block_outlined,
          ),
        ],
      ),
    );
  }
}

class ManageVenuesScreen extends StatelessWidget {
  const ManageVenuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Manage venues',
      body: Center(
        child: Text(
            'Add/edit venue placeholder and blocked slot management will live here.'),
      ),
    );
  }
}
