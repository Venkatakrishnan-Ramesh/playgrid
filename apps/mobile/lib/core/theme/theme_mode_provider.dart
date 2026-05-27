import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide light/dark/system theme selection.
///
/// Held in memory for now; wire to persistent storage (shared_preferences /
/// secure storage) when a storage dependency is added.
final StateProvider<ThemeMode> themeModeProvider =
    StateProvider<ThemeMode>((Ref ref) => ThemeMode.system);
