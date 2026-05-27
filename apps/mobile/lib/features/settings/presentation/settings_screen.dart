import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MainShell(
      title: 'Settings',
      index: 5,
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Appearance',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: <ThemeMode>{themeMode},
            onSelectionChanged: (Set<ThemeMode> selection) =>
                ref.read(themeModeProvider.notifier).state = selection.first,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Friends'),
            subtitle: const Text('Manage connections and requests'),
            onTap: () => context.push(RoutePaths.friends),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('View your alerts'),
            onTap: () => context.push(RoutePaths.notifications),
          ),
          const Divider(),
          ListTile(
            title: const Text('Privacy policy'),
            subtitle: const Text('Placeholder link for the app store listing'),
            onTap: () => context.push(RoutePaths.privacyPolicy),
          ),
          ListTile(
            title: const Text('Account deletion request'),
            subtitle: const Text('Request data removal'),
            onTap: () => context.push(RoutePaths.accountDeletion),
          ),
          ListTile(
            title: const Text('Logout'),
            subtitle: const Text('Sign out of the app'),
            onTap: () async {
              await controller.signOut();
              if (context.mounted) {
                context.go(RoutePaths.login);
              }
            },
          ),
        ],
      ),
    );
  }
}

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final PlayGridController controller =
            ref.watch(playGridControllerProvider);
        return AppShell(
          title: 'Account deletion',
          body: ListView(
            children: <Widget>[
              const Text('This request is a placeholder flow for the MVP.'),
              const SizedBox(height: 16),
              TextField(
                controller: _reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await controller.requestAccountDeletion(_reason.text);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Deletion request submitted.')),
                  );
                },
                child: const Text('Request deletion'),
              ),
            ],
          ),
        );
      },
    );
  }
}
