import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../shared/models/playgrid_models.dart';
import '../../auth/domain/playgrid_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController(text: 'arjun@acme.com');
  final TextEditingController _password = TextEditingController(text: 'password123');
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final PlayGridController controller = ref.watch(playGridControllerProvider);
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text('PlayGrid Club', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          const Text('Sign in to coordinate games, venues, and tournaments.'),
                          const SizedBox(height: 24),
                          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _password,
                            decoration: const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                          ),
                          if (_error != null) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () async {
                              try {
                                await controller.signIn(email: _email.text, password: _password.text);
                                if (context.mounted) {
                                  context.go(RoutePaths.home);
                                }
                              } catch (error) {
                                setState(() => _error = error.toString());
                              }
                            },
                            child: const Text('Login'),
                          ),
                          TextButton(
                            onPressed: () => context.go(RoutePaths.signup),
                            child: const Text('Create an account'),
                          ),
                          TextButton(
                            onPressed: () => context.go(RoutePaths.forgotPassword),
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _name = TextEditingController(text: 'New Player');
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController(text: 'password123');
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final PlayGridController controller = ref.watch(playGridControllerProvider);
        return Scaffold(
          appBar: AppBar(title: const Text('Create account')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 16),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  try {
                    await controller.signUp(name: _name.text, email: _email.text, password: _password.text);
                    if (context.mounted) {
                      context.go(RoutePaths.profileSetup);
                    }
                  } catch (error) {
                    setState(() => _error = error.toString());
                  }
                },
                child: const Text('Sign up'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final PlayGridController controller = ref.watch(playGridControllerProvider);
        return Scaffold(
          appBar: AppBar(title: const Text('Reset password')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              const Text('Password reset is a placeholder flow for the MVP.'),
              const SizedBox(height: 16),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await controller.sendPasswordReset(email: _email.text);
                  setState(() => _message = 'Reset instructions sent if the email exists.');
                },
                child: const Text('Send reset link'),
              ),
              if (_message != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(_message!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _department = TextEditingController();
  final TextEditingController _avatarUrl = TextEditingController();
  final Map<String, SkillLevel> _selectedSports = <String, SkillLevel>{};

  @override
  void dispose() {
    _name.dispose();
    _department.dispose();
    _avatarUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final PlayGridController controller = ref.watch(playGridControllerProvider);
        final PlayGridState state = controller.state;
        final AppUserProfile? profile = state.profile;

        if (_name.text.isEmpty) {
          _name.text = profile?.name ?? 'Your name';
        }
        if (_department.text.isEmpty) {
          _department.text = profile?.department ?? 'Department';
        }
        if (_avatarUrl.text.isEmpty) {
          _avatarUrl.text = profile?.avatarUrl ?? '';
        }
        for (final SportPreference skill in profile?.skills ?? const <SportPreference>[]) {
          _selectedSports.putIfAbsent(skill.sportId, () => skill.skillLevel);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Complete your profile')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 16),
              TextField(controller: _department, decoration: const InputDecoration(labelText: 'Department')),
              const SizedBox(height: 16),
              TextField(controller: _avatarUrl, decoration: const InputDecoration(labelText: 'Avatar URL')),
              const SizedBox(height: 24),
              Text('Sports interests', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.sports.map((Sport sport) {
                  final SkillLevel current = _selectedSports[sport.id] ?? SkillLevel.beginner;
                  return InputChip(
                    label: Text('${sport.name} · ${current.label}'),
                    selected: _selectedSports.containsKey(sport.id),
                    onPressed: () {
                      setState(() {
                        _selectedSports[sport.id] = switch (current) {
                          SkillLevel.beginner => SkillLevel.intermediate,
                          SkillLevel.intermediate => SkillLevel.advanced,
                          SkillLevel.advanced => SkillLevel.elite,
                          SkillLevel.elite => SkillLevel.beginner,
                        };
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final List<SportPreference> preferences = _selectedSports.entries
                      .map(
                        (MapEntry<String, SkillLevel> entry) => SportPreference(
                          sportId: entry.key,
                          skillLevel: entry.value,
                        ),
                      )
                      .toList(growable: false);

                  await controller.saveProfile(
                    name: _name.text,
                    department: _department.text,
                    avatarUrl: _avatarUrl.text.isEmpty ? null : _avatarUrl.text,
                    skillLevel: preferences.isEmpty ? SkillLevel.beginner : preferences.first.skillLevel,
                    sportsPreferences: preferences,
                  );
                  if (context.mounted) {
                    context.go(RoutePaths.home);
                  }
                },
                child: const Text('Save profile'),
              ),
            ],
          ),
        );
      },
    );
  }
}
