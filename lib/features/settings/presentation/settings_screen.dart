import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/main_shell.dart';
import '../../auth/domain/playgrid_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget buildWithRef(BuildContext context, WidgetRef ref) {
    final PlayGridController controller = ref.watch(playGridControllerProvider);

    return MainShell(
      title: 'Settings',
      index: 5,
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('Privacy policy'),
            subtitle: const Text('Placeholder link for the app store listing'),
            onTap: () => context.go(RoutePaths.privacyPolicy),
          ),
          ListTile(
            title: const Text('Account deletion request'),
            subtitle: const Text('Request data removal'),
            onTap: () => context.go(RoutePaths.accountDeletion),
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
        final PlayGridController controller = ref.watch(playGridControllerProvider);
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
                    const SnackBar(content: Text('Deletion request submitted.')),
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
