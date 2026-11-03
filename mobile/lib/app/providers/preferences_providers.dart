import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/preferences_repository.dart';
import 'core_providers.dart';

final themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref
      .watch(preferencesRepositoryProvider)
      .watch(PreferenceKey.themeMode)
      .map((v) => ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system)),
);

/// What the app calls the user in greetings. Empty when not set.
final displayNameProvider = StreamProvider<String>(
  (ref) => ref.watch(preferencesRepositoryProvider).watch(PreferenceKey.displayName).map((v) => v ?? ''),
);
